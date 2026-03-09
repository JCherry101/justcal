import os
import threading
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter
from pydantic import BaseModel

from models import Task, Document
from services import db
from services.documents import extract_text
from services.gemini import call_gemini_for_tasks
from services.rag import store_document_with_embeddings

router = APIRouter()


class IngestRequest(BaseModel):
    file_path: str


@router.post("/documents/ingest")
async def ingest_document(req: IngestRequest) -> list[Task]:
    raw_text = extract_text(req.file_path)
    filename = os.path.basename(req.file_path)

    tasks_raw = await call_gemini_for_tasks(raw_text)
    tasks: list[Task] = []
    for rt in tasks_raw:
        tasks.append(Task(
            id=str(uuid.uuid4()),
            title=rt["title"],
            deadline=rt["deadline"],
            priority=rt.get("priority", "medium").lower().strip(),
            description=rt.get("description", ""),
            synced=False,
        ))

    # Store embeddings in background thread
    task_count = len(tasks)
    text_copy = raw_text
    fn_copy = filename
    threading.Thread(
        target=store_document_with_embeddings,
        args=(fn_copy, text_copy, task_count),
        daemon=True,
    ).start()

    return tasks


@router.get("/documents")
def get_documents() -> list[Document]:
    conn = db.get_connection()
    rows = conn.execute(
        "SELECT d.id, d.filename, d.ingested_at, "
        "(SELECT COUNT(*) FROM chunks c WHERE c.document_id = d.id) AS chunk_count, "
        "0 AS task_count "
        "FROM documents d ORDER BY d.ingested_at DESC"
    ).fetchall()
    return [
        Document(
            id=r["id"],
            filename=r["filename"],
            ingested_at=r["ingested_at"],
            chunk_count=r["chunk_count"],
            task_count=r["task_count"],
        )
        for r in rows
    ]


@router.delete("/documents/{doc_id}")
def delete_document(doc_id: str) -> dict:
    conn = db.get_connection()
    # CASCADE deletes embeddings -> chunks automatically via FK
    conn.execute("DELETE FROM documents WHERE id = ?", (doc_id,))
    # Clear chat history so the LLM no longer remembers the document
    conn.execute("DELETE FROM chat_history")
    conn.commit()
    return {"ok": True}
