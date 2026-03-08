import asyncio
import os
import secrets
import threading
import webbrowser
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

import httpx
import keyring

GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_REVOKE_URL = "https://oauth2.googleapis.com/revoke"
KEYRING_SERVICE = "justcal"

# These must be set as environment variables at build/run time
_client_id = os.environ.get("GOOGLE_CLIENT_ID", "")
_client_secret = os.environ.get("GOOGLE_CLIENT_SECRET", "")


class _OAuthCallbackHandler(BaseHTTPRequestHandler):
    """Tiny HTTP handler that captures the OAuth redirect code."""

    code: str | None = None

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)
        code = params.get("code", [None])[0]
        if code:
            _OAuthCallbackHandler.code = code
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(
                b"<html><body><h2>Authentication successful!</h2>"
                b"<p>You can close this tab and return to JustCal.</p></body></html>"
            )
        else:
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b"Missing code parameter")

    def log_message(self, format: str, *args: object) -> None:
        pass  # silence request logs


async def start_google_auth() -> None:
    """Open the browser for Google OAuth and wait for the callback."""
    if not _client_id:
        raise RuntimeError("GOOGLE_CLIENT_ID env var not set")

    _OAuthCallbackHandler.code = None
    server = HTTPServer(("127.0.0.1", 0), _OAuthCallbackHandler)
    port = server.server_address[1]
    redirect_uri = f"http://127.0.0.1:{port}"

    scopes = " ".join([
        "https://www.googleapis.com/auth/calendar",
        "https://www.googleapis.com/auth/generativelanguage",
        "openid",
        "email",
    ])

    state = secrets.token_urlsafe(16)
    auth_url = (
        f"{GOOGLE_AUTH_URL}?"
        f"client_id={_client_id}&"
        f"redirect_uri={redirect_uri}&"
        f"response_type=code&"
        f"scope={scopes}&"
        f"access_type=offline&"
        f"prompt=consent&"
        f"state={state}"
    )

    webbrowser.open(auth_url)

    # Handle the callback in a thread so we don't block the event loop
    def _serve() -> None:
        server.handle_request()  # handles exactly one request
        server.server_close()

    loop = asyncio.get_event_loop()
    await loop.run_in_executor(None, _serve)

    code = _OAuthCallbackHandler.code
    if not code:
        raise RuntimeError("OAuth callback did not receive an authorization code")

    await _exchange_code(code, redirect_uri)


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
        raise RuntimeError(f"Token exchange failed: {resp.text}")

    data = resp.json()
    keyring.set_password(KEYRING_SERVICE, "google-access-token", data["access_token"])
    if "refresh_token" in data:
        keyring.set_password(KEYRING_SERVICE, "google-refresh-token", data["refresh_token"])


def get_google_auth_status() -> bool:
    try:
        token = keyring.get_password(KEYRING_SERVICE, "google-refresh-token")
        return token is not None and token != ""
    except Exception:
        return False


async def revoke_google_auth() -> None:
    token = keyring.get_password(KEYRING_SERVICE, "google-refresh-token")
    if token:
        async with httpx.AsyncClient(timeout=15) as client:
            await client.post(GOOGLE_REVOKE_URL, data={"token": token})
        try:
            keyring.delete_password(KEYRING_SERVICE, "google-refresh-token")
        except Exception:
            pass
    try:
        keyring.delete_password(KEYRING_SERVICE, "google-access-token")
    except Exception:
        pass


async def get_valid_access_token() -> str:
    # Try cached access token first
    token = keyring.get_password(KEYRING_SERVICE, "google-access-token")
    if token:
        return token

    # Refresh
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
        raise RuntimeError(f"Token refresh failed: {resp.text}")

    data = resp.json()
    access = data["access_token"]
    keyring.set_password(KEYRING_SERVICE, "google-access-token", access)
    return access
