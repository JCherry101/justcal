from fastapi import APIRouter

from services.google_auth import (
    get_google_auth_status,
    revoke_google_auth,
    start_google_auth,
)

router = APIRouter()


@router.post("/auth/google/start")
async def google_auth_start() -> dict:
    await start_google_auth()
    return {"ok": True}


@router.get("/auth/google/status")
def google_auth_status() -> dict:
    return {"connected": get_google_auth_status()}


@router.post("/auth/google/revoke")
async def google_auth_revoke() -> dict:
    await revoke_google_auth()
    return {"ok": True}
