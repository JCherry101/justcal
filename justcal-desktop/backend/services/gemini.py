import json
from datetime import datetime, timezone

import httpx
import keyring

GEMINI_API_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
)
KEYRING_SERVICE = "justcal"


async def get_gemini_auth() -> tuple[bool, str]:
    """Return (use_api_key, auth_value).

    Checks for a stored Gemini API key first (Option A).
    Falls back to Google OAuth access token (Option B).
    """
    key = keyring.get_password(KEYRING_SERVICE, "gemini-api-key")
    if key:
        return True, key

    from services.google_auth import get_valid_access_token

    token = await get_valid_access_token()
    return False, token


async def call_gemini_for_tasks(raw_text: str) -> list[dict]:
    """Send document text to Gemini, get back a list of task dicts."""
    use_api_key, auth_value = await get_gemini_auth()
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    prompt = (
        f"Today's date is {today}. Extract every assignment, exam, project, or deadline "
        f"from the following course document text.\n"
        f'Return ONLY a valid JSON array (no markdown, no explanation) where each element is:\n'
        f'{{"title":"string","deadline":"YYYY-MM-DD","priority":"high|medium|low","description":"string"}}\n'
        f"If a date is relative (e.g. 'Week 3'), calculate from today. "
        f"If a date is ambiguous, use the nearest future occurrence.\n"
        f"Do not include any text before or after the JSON array.\n\n"
        f"DOCUMENT TEXT:\n{raw_text}"
    )

    body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"responseMimeType": "application/json"},
    }

    url = f"{GEMINI_API_URL}?key={auth_value}" if use_api_key else GEMINI_API_URL
    headers = {} if use_api_key else {"Authorization": f"Bearer {auth_value}"}

    async with httpx.AsyncClient(timeout=120) as client:
        resp = await client.post(url, json=body, headers=headers)

    if resp.status_code != 200:
        raise RuntimeError(f"Gemini API error {resp.status_code}: {resp.text}")

    data = resp.json()
    json_text = data["candidates"][0]["content"]["parts"][0]["text"]
    return json.loads(json_text)


async def rag_chat_completion(
    user_message: str,
    context_chunks: list[tuple[str, float]],
    tasks_context: str,
    history: list[tuple[str, str]],
) -> str:
    """Build a RAG-augmented prompt and call Gemini for a chat response."""
    use_api_key, auth_value = await get_gemini_auth()
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    chunks_str = "\n---\n".join(
        f"[relevance: {score:.2f}]\n{text}" for text, score in context_chunks
    )
    history_str = "\n".join(f"{role}: {content}" for role, content in history)

    system_prompt = (
        f"You are JustCal Assistant, an intelligent scheduling helper. Today is {today}.\n"
        f"You have access to the user's course documents and schedule.\n\n"
        f"CURRENT TASKS/SCHEDULE:\n{tasks_context}\n\n"
        f"RELEVANT DOCUMENT EXCERPTS:\n{chunks_str}\n\n"
        f"CONVERSATION HISTORY:\n{history_str}\n\n"
        f"Answer the user's question helpfully and concisely. Reference specific deadlines, "
        f"tasks, or document content when relevant. If you don't have enough information, say so."
    )

    body = {
        "contents": [
            {"parts": [{"text": system_prompt}]},
            {"parts": [{"text": user_message}]},
        ],
        "generationConfig": {"responseMimeType": "text/plain"},
    }

    url = f"{GEMINI_API_URL}?key={auth_value}" if use_api_key else GEMINI_API_URL
    headers = {} if use_api_key else {"Authorization": f"Bearer {auth_value}"}

    async with httpx.AsyncClient(timeout=120) as client:
        resp = await client.post(url, json=body, headers=headers)

    if resp.status_code != 200:
        raise RuntimeError(f"Gemini API error {resp.status_code}: {resp.text}")

    data = resp.json()
    return data["candidates"][0]["content"]["parts"][0]["text"]
