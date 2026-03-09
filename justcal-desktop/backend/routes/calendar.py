import uuid

import httpx
from fastapi import APIRouter

from models import Task, Milestone
from services import db
from services.google_auth import (
    get_google_auth_status,
    get_valid_access_token,
)
from routes.tasks import _generate_milestones

GOOGLE_CALENDAR_API = "https://www.googleapis.com/calendar/v3"

router = APIRouter()


@router.post("/calendar/sync")
async def sync_tasks_to_calendars(tasks: list[Task]) -> dict:
    status = get_google_auth_status()
    if not status["connected"]:
        raise RuntimeError("Google Calendar not connected. Please connect in Settings.")

    all_milestones: list[Milestone] = []
    for task in tasks:
        all_milestones.extend(_generate_milestones(task))

    # Persist milestones
    conn = db.get_connection()
    for ms in all_milestones:
        conn.execute(
            "INSERT OR REPLACE INTO milestones (id,task_id,title,due_date,kind) VALUES (?,?,?,?,?)",
            (ms.id, ms.task_id, ms.title, ms.due_date, ms.kind),
        )
    conn.commit()

    access_token = await get_valid_access_token()
    synced = 0

    async with httpx.AsyncClient(timeout=30) as client:
        for ms in all_milestones:
            event = {
                "summary": ms.title,
                "start": {"date": ms.due_date},
                "end": {"date": ms.due_date},
            }
            resp = await client.post(
                f"{GOOGLE_CALENDAR_API}/calendars/primary/events",
                headers={"Authorization": f"Bearer {access_token}"},
                json=event,
            )
            if resp.status_code == 200:
                created = resp.json()
                conn.execute(
                    "INSERT OR REPLACE INTO calendar_events (id,provider,event_id,milestone_id) "
                    "VALUES (?,'google',?,?)",
                    (str(uuid.uuid4()), created.get("id", ""), ms.id),
                )
                synced += 1

    conn.commit()
    s = "" if synced == 1 else "s"
    return {"message": f"Synced {synced} milestone{s} successfully."}
