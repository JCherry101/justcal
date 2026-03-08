import keyring
from fastapi import APIRouter
from pydantic import BaseModel

KEYRING_SERVICE = "justcal"

router = APIRouter()


class GeminiKeyRequest(BaseModel):
    key: str


@router.post("/settings/gemini-key")
def save_gemini_key(req: GeminiKeyRequest) -> dict:
    keyring.set_password(KEYRING_SERVICE, "gemini-api-key", req.key)
    return {"ok": True}


@router.get("/settings/gemini-key/status")
def get_gemini_key_status() -> dict:
    key = keyring.get_password(KEYRING_SERVICE, "gemini-api-key")
    return {"saved": bool(key)}
