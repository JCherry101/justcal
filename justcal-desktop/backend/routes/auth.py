from fastapi import APIRouter, HTTPException

from services.google_auth import (
    get_google_auth_status,
    revoke_google_auth,
    start_google_auth,
)

router = APIRouter()


@router.post("/auth/google/start")
async def google_auth_start() -> dict:
    try:
        result = await start_google_auth()
    except RuntimeError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return result


@router.get("/auth/google/status")
def google_auth_status() -> dict:
    return get_google_auth_status()


@router.post("/auth/google/revoke")
async def google_auth_revoke() -> dict:
    await revoke_google_auth()
    return {"ok": True}
