import asyncio
import logging
import os
import secrets
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

import httpx
import keyring

logger = logging.getLogger("justcal.auth")

GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_REVOKE_URL = "https://oauth2.googleapis.com/revoke"
GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo"
KEYRING_SERVICE = "justcal"

_client_id = os.environ.get("GOOGLE_CLIENT_ID", "")
_client_secret = os.environ.get("GOOGLE_CLIENT_SECRET", "")

# Module-level state token for CSRF validation
_expected_state: str | None = None

# ── HTML pages served to the browser after OAuth callback ──

_SUCCESS_HTML = """\
<!DOCTYPE html>
<html>
<head><title>Authorization Successful</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
         display:flex; justify-content:center; align-items:center;
         min-height:100vh; margin:0; background:#f8f8f6; }
  .card { background:#fff; padding:48px; border-radius:16px;
          box-shadow:0 4px 24px rgba(0,0,0,.08); text-align:center; max-width:420px; }
  .icon { width:64px; height:64px; margin:0 auto 20px; line-height:64px;
          font-size:32px; background:#e8f5e9; border-radius:50%; color:#43a047; }
  h1 { font-size:20px; margin:0 0 8px; color:#1a1a1a; }
  p  { font-size:14px; color:#666; margin:4px 0; }
</style></head>
<body><div class="card">
  <div class="icon">&#10003;</div>
  <h1>Authorization Successful!</h1>
  <p>Your Google Calendar has been connected to JustCal.</p>
  <p>You can close this tab and return to the app.</p>
</div></body></html>"""

_ERROR_HTML = """\
<!DOCTYPE html>
<html>
<head><title>Authorization Failed</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
         display:flex; justify-content:center; align-items:center;
         min-height:100vh; margin:0; background:#f8f8f6; }
  .card { background:#fff; padding:48px; border-radius:16px;
          box-shadow:0 4px 24px rgba(0,0,0,.08); text-align:center; max-width:420px; }
  .icon { width:64px; height:64px; margin:0 auto 20px; line-height:64px;
          font-size:32px; background:#fce4ec; border-radius:50%; color:#e53935; }
  h1 { font-size:20px; margin:0 0 8px; color:#1a1a1a; }
  p  { font-size:14px; color:#666; margin:4px 0; }
</style></head>
<body><div class="card">
  <div class="icon">&#10007;</div>
  <h1>Authorization Failed</h1>
  <p>{{ERROR_MESSAGE}}</p>
  <p>Please close this tab and try again in JustCal.</p>
</div></body></html>"""

_SECURITY_HTML = """\
<!DOCTYPE html>
<html>
<head><title>Security Error</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
         display:flex; justify-content:center; align-items:center;
         min-height:100vh; margin:0; background:#f8f8f6; }
  .card { background:#fff; padding:48px; border-radius:16px;
          box-shadow:0 4px 24px rgba(0,0,0,.08); text-align:center; max-width:420px; }
  .icon { width:64px; height:64px; margin:0 auto 20px; line-height:64px;
          font-size:32px; background:#fff8e1; border-radius:50%; color:#f9a825; }
  h1 { font-size:20px; margin:0 0 8px; color:#1a1a1a; }
  p  { font-size:14px; color:#666; margin:4px 0; }
</style></head>
<body><div class="card">
  <div class="icon">&#9888;</div>
  <h1>Security Error</h1>
  <p>Invalid state parameter &mdash; this could be a CSRF attack.</p>
  <p>For your security, authorization was stopped.</p>
</div></body></html>"""


# ── OAuth callback handler ──

class _OAuthCallbackHandler(BaseHTTPRequestHandler):
    """Tiny HTTP handler that captures the OAuth redirect code."""

    code: str | None = None
    error: str | None = None

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)

        # Check for error from Google (e.g. user denied access)
        err = params.get("error", [None])[0]
        if err:
            _OAuthCallbackHandler.error = err
            html = _ERROR_HTML.replace("{{ERROR_MESSAGE}}", err)
            self._respond(400, html)
            return

        # Validate state parameter to prevent CSRF
        state = params.get("state", [None])[0]
        if state != _expected_state:
            logger.warning("OAuth state mismatch — possible CSRF attempt")
            _OAuthCallbackHandler.error = "state_mismatch"
            self._respond(403, _SECURITY_HTML)
            return

        code = params.get("code", [None])[0]
        if code:
            _OAuthCallbackHandler.code = code
            self._respond(200, _SUCCESS_HTML)
        else:
            _OAuthCallbackHandler.error = "missing_code"
            html = _ERROR_HTML.replace("{{ERROR_MESSAGE}}", "No authorization code received.")
            self._respond(400, html)

    def _respond(self, status: int, html: str) -> None:
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(html.encode())

    def log_message(self, format: str, *args: object) -> None:
        pass  # silence request logs


# ── Public API ──

async def start_google_auth() -> dict:
    """Open the browser for Google OAuth and wait for the callback.

    Returns {"ok": True, "email": "..."} on success.
    """
    global _expected_state
    if not _client_id:
        raise RuntimeError("GOOGLE_CLIENT_ID env var not set")

    _OAuthCallbackHandler.code = None
    _OAuthCallbackHandler.error = None
    server = HTTPServer(("127.0.0.1", 0), _OAuthCallbackHandler)
    port = server.server_address[1]
    redirect_uri = f"http://127.0.0.1:{port}"

    scopes = " ".join([
        "https://www.googleapis.com/auth/calendar",
        "https://www.googleapis.com/auth/userinfo.email",
        "openid",
        "email",
    ])

    _expected_state = secrets.token_urlsafe(32)
    auth_url = (
        f"{GOOGLE_AUTH_URL}?"
        f"client_id={_client_id}&"
        f"redirect_uri={redirect_uri}&"
        f"response_type=code&"
        f"scope={scopes}&"
        f"access_type=offline&"
        f"prompt=consent&"
        f"state={_expected_state}"
    )

    import webbrowser
    webbrowser.open(auth_url)

    # Handle the callback in a thread with a 5-minute timeout
    server.timeout = 300  # seconds

    def _serve() -> None:
        server.handle_request()  # handles exactly one request then returns
        server.server_close()

    loop = asyncio.get_event_loop()
    await loop.run_in_executor(None, _serve)

    # Check what happened
    if _OAuthCallbackHandler.error:
        raise RuntimeError(f"Authorization failed: {_OAuthCallbackHandler.error}")

    code = _OAuthCallbackHandler.code
    if not code:
        raise RuntimeError("Authorization timed out (5 minutes). Please try again.")

    await _exchange_code(code, redirect_uri)

    # Fetch user's email for display
    email = await _fetch_user_email()

    return {"ok": True, "email": email}


async def _exchange_code(code: str, redirect_uri: str) -> None:
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            GOOGLE_TOKEN_URL,
            data={
                "code": code,
                "client_id": _client_id,
                "client_secret": _client_secret,
                "redirect_uri": redirect_uri,
                "grant_type": "authorization_code",
            },
        )
    if resp.status_code != 200:
        logger.error("Token exchange failed: %s", resp.text)
        raise RuntimeError("Token exchange failed. Please try again.")

    data = resp.json()
    keyring.set_password(KEYRING_SERVICE, "google-access-token", data["access_token"])
    if "refresh_token" in data:
        keyring.set_password(KEYRING_SERVICE, "google-refresh-token", data["refresh_token"])
    # Store token expiry as a unix timestamp
    expires_in = data.get("expires_in", 3600)
    expiry = str(int(time.time()) + int(expires_in))
    keyring.set_password(KEYRING_SERVICE, "google-token-expiry", expiry)


async def _fetch_user_email() -> str:
    """Call Google userinfo endpoint to get the authenticated user's email."""
    access_token = await get_valid_access_token()
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(
            GOOGLE_USERINFO_URL,
            headers={"Authorization": f"Bearer {access_token}"},
        )
    if resp.status_code != 200:
        logger.warning("Failed to fetch user email: %s", resp.status_code)
        return ""
    email = resp.json().get("email", "")
    if email:
        keyring.set_password(KEYRING_SERVICE, "google-email", email)
    return email


def get_google_auth_status() -> dict:
    """Return {"connected": bool, "email": str}."""
    try:
        token = keyring.get_password(KEYRING_SERVICE, "google-refresh-token")
        connected = token is not None and token != ""
        email = ""
        if connected:
            email = keyring.get_password(KEYRING_SERVICE, "google-email") or ""
        return {"connected": connected, "email": email}
    except Exception:
        return {"connected": False, "email": ""}


async def revoke_google_auth() -> None:
    token = keyring.get_password(KEYRING_SERVICE, "google-refresh-token")
    if token:
        async with httpx.AsyncClient(timeout=15) as client:
            await client.post(GOOGLE_REVOKE_URL, data={"token": token})
    for key in ("google-access-token", "google-refresh-token",
                "google-token-expiry", "google-email"):
        try:
            keyring.delete_password(KEYRING_SERVICE, key)
        except Exception:
            pass


async def get_valid_access_token() -> str:
    """Return a valid access token, refreshing automatically if expired."""
    # Check if current token is still valid (with 5-minute buffer)
    try:
        expiry_str = keyring.get_password(KEYRING_SERVICE, "google-token-expiry")
        if expiry_str:
            expiry = int(expiry_str)
            buffer = 300  # 5 minutes
            if time.time() + buffer < expiry:
                token = keyring.get_password(KEYRING_SERVICE, "google-access-token")
                if token:
                    return token
    except (ValueError, TypeError):
        pass

    # Token expired or missing — refresh
    refresh = keyring.get_password(KEYRING_SERVICE, "google-refresh-token")
    if not refresh:
        raise RuntimeError("Not authenticated with Google. Connect in Settings.")

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            GOOGLE_TOKEN_URL,
            data={
                "refresh_token": refresh,
                "client_id": _client_id,
                "client_secret": _client_secret,
                "grant_type": "refresh_token",
            },
        )
    if resp.status_code != 200:
        logger.error("Token refresh failed: %s", resp.text)
        raise RuntimeError("Token refresh failed. Please reconnect Google in Settings.")

    data = resp.json()
    access = data["access_token"]
    keyring.set_password(KEYRING_SERVICE, "google-access-token", access)

    # Update expiry
    expires_in = data.get("expires_in", 3600)
    expiry = str(int(time.time()) + int(expires_in))
    keyring.set_password(KEYRING_SERVICE, "google-token-expiry", expiry)

    return access
