from datetime import datetime, timezone

from fastapi import APIRouter
from pydantic import BaseModel

from models import ChatMessage
from services import db
from services.gemini import rag_chat_completion
from services.rag import retrieve_relevant_chunks

router = APIRouter()


class ChatSendRequest(BaseModel):
    message: str


@router.get("/chat/history")
def chat_get_history() -> list[ChatMessage]:
    conn = db.get_connection()
    rows = conn.execute(
        "SELECT role, content FROM chat_history ORDER BY id ASC"
    ).fetchall()
    return [ChatMessage(role=r["role"], content=r["content"]) for r in rows]


@router.post("/chat/send")
async def chat_send(req: ChatSendRequest) -> ChatMessage:
    conn = db.get_connection()
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Store user message
    conn.execute(
        "INSERT INTO chat_history (role, content, created_at) VALUES ('user', ?, ?)",
        (req.message, now),
    )
    conn.commit()

    # Retrieve relevant chunks
    relevant = retrieve_relevant_chunks(req.message, top_k=5)

    # Task context
    rows = conn.execute(
        "SELECT title, deadline, priority, description FROM tasks ORDER BY deadline"
    ).fetchall()
    tasks_context = "\n".join(
        f"- {r['title']} (due: {r['deadline']}, priority: {r['priority']}): {r['description'] or ''}"
        for r in rows
    )

    # Recent history
    hist_rows = conn.execute(
        "SELECT role, content FROM chat_history ORDER BY id DESC LIMIT 10"
    ).fetchall()
    history = [(r["role"], r["content"]) for r in reversed(hist_rows)]

    answer = await rag_chat_completion(req.message, relevant, tasks_context, history)

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    conn.execute(
        "INSERT INTO chat_history (role, content, created_at) VALUES ('assistant', ?, ?)",
        (answer, now),
    )
    conn.commit()

    return ChatMessage(role="assistant", content=answer)


@router.delete("/chat/history")
def chat_clear_history() -> dict:
    conn = db.get_connection()
    conn.execute("DELETE FROM chat_history")
    conn.commit()
    return {"ok": True}
