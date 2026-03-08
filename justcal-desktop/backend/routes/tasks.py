import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter

from models import Task, Milestone
from services import db
from services.gemini import call_gemini_for_tasks

router = APIRouter()


def _generate_milestones(task: Task) -> list[Milestone]:
    today = datetime.now(timezone.utc).date()
    try:
        deadline = datetime.strptime(task.deadline, "%Y-%m-%d").date()
    except ValueError:
        deadline = today + timedelta(days=7)

    days_until = max((deadline - today).days, 0)
    milestones: list[Milestone] = []

    milestones.append(Milestone(
        id=str(uuid.uuid4()),
        task_id=task.id,
        title=f"\U0001f3af Due: {task.title}",
        due_date=task.deadline,
        kind="final",
    ))

    if days_until >= 3:
        d = max(deadline - timedelta(days=2), today)
        milestones.append(Milestone(
            id=str(uuid.uuid4()),
            task_id=task.id,
            title=f"\U0001f50d Review: {task.title}",
            due_date=d.strftime("%Y-%m-%d"),
            kind="review",
        ))

    if days_until >= 6:
        d = max(deadline - timedelta(days=5), today)
        milestones.append(Milestone(
            id=str(uuid.uuid4()),
            task_id=task.id,
            title=f"\u270f\ufe0f Draft: {task.title}",
            due_date=d.strftime("%Y-%m-%d"),
            kind="draft",
        ))

    if days_until >= 8:
        d = max(deadline - timedelta(days=7), today)
        milestones.append(Milestone(
            id=str(uuid.uuid4()),
            task_id=task.id,
            title=f"\U0001f680 Start: {task.title}",
            due_date=d.strftime("%Y-%m-%d"),
            kind="start",
        ))

    return milestones


@router.get("/tasks")
def get_all_tasks() -> list[Task]:
    conn = db.get_connection()
    rows = conn.execute(
        "SELECT id, title, deadline, priority, description, synced FROM tasks ORDER BY deadline"
    ).fetchall()
    return [
        Task(
            id=r["id"],
            title=r["title"],
            deadline=r["deadline"],
            priority=r["priority"],
            description=r["description"] or "",
            synced=bool(r["synced"]),
        )
        for r in rows
    ]


@router.post("/tasks")
def save_tasks(tasks: list[Task]) -> dict:
    conn = db.get_connection()
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    for task in tasks:
        conn.execute(
            "INSERT OR REPLACE INTO tasks (id,title,deadline,priority,description,created_at,synced) "
            "VALUES (?,?,?,?,?,?,?)",
            (task.id, task.title, task.deadline, task.priority, task.description, now, int(task.synced)),
        )
        for ms in _generate_milestones(task):
            conn.execute(
                "INSERT OR REPLACE INTO milestones (id,task_id,title,due_date,kind) VALUES (?,?,?,?,?)",
                (ms.id, ms.task_id, ms.title, ms.due_date, ms.kind),
            )
    conn.commit()
    return {"ok": True}


@router.post("/tasks/from-chat")
async def create_tasks_from_chat() -> list[Task]:
    conn = db.get_connection()
    rows = conn.execute("SELECT raw_text FROM documents").fetchall()
    all_text = "\n\n---\n\n".join(r["raw_text"] for r in rows)
    if not all_text.strip():
        raise ValueError("No documents ingested yet. Upload documents first.")

    raw_tasks = await call_gemini_for_tasks(all_text)
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    tasks: list[Task] = []
    for rt in raw_tasks:
        t = Task(
            id=str(uuid.uuid4()),
            title=rt["title"],
            deadline=rt["deadline"],
            priority=rt.get("priority", "medium").lower().strip(),
            description=rt.get("description", ""),
            synced=False,
        )
        tasks.append(t)
        conn.execute(
            "INSERT OR REPLACE INTO tasks (id,title,deadline,priority,description,created_at,synced) "
            "VALUES (?,?,?,?,?,?,0)",
            (t.id, t.title, t.deadline, t.priority, t.description, now),
        )
        for ms in _generate_milestones(t):
            conn.execute(
                "INSERT OR REPLACE INTO milestones (id,task_id,title,due_date,kind) VALUES (?,?,?,?,?)",
                (ms.id, ms.task_id, ms.title, ms.due_date, ms.kind),
            )
    conn.commit()
    return tasks


@router.get("/milestones")
def get_all_milestones() -> list[Milestone]:
    conn = db.get_connection()
    rows = conn.execute(
        "SELECT id, task_id, title, due_date, kind FROM milestones ORDER BY due_date"
    ).fetchall()
    return [
        Milestone(id=r["id"], task_id=r["task_id"], title=r["title"], due_date=r["due_date"], kind=r["kind"])
        for r in rows
    ]
