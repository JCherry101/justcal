import uuid
from datetime import datetime, timezone

import numpy as np

from services import db, embedder
from services.documents import chunk_text


def store_document_with_embeddings(
    filename: str, raw_text: str, task_count: int
) -> None:
    doc_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    chunks = chunk_text(raw_text)

    conn = db.get_connection()
    conn.execute(
        "INSERT INTO documents (id, filename, raw_text, ingested_at) VALUES (?,?,?,?)",
        (doc_id, filename, raw_text, now),
    )
    conn.commit()

    # Embed all chunks in one batch for efficiency
    try:
        vectors = embedder.embed_batch([c for c in chunks])
    except RuntimeError as e:
        print(f"[RAG] Embedding failed: {e}")
        return

    for i, (chunk_content, vec) in enumerate(zip(chunks, vectors)):
        chunk_id = str(uuid.uuid4())
        conn.execute(
            "INSERT INTO chunks (id, document_id, content, chunk_index) VALUES (?,?,?,?)",
            (chunk_id, doc_id, chunk_content, i),
        )
        rowid = conn.execute("SELECT last_insert_rowid()").fetchone()[0]
        conn.execute(
            "INSERT INTO embeddings (chunk_rowid, embedding) VALUES (?,?)",
            (rowid, embedder.vec_to_bytes(vec)),
        )
    conn.commit()


def retrieve_relevant_chunks(query: str, top_k: int = 5) -> list[tuple[str, float]]:
    """Return the *top_k* most relevant (content, similarity) pairs."""
    query_vec = np.array(embedder.embed_text(query), dtype=np.float32)
    conn = db.get_connection()

    rows = conn.execute(
        "SELECT c.content, e.embedding "
        "FROM embeddings e JOIN chunks c ON c.rowid = e.chunk_rowid"
    ).fetchall()

    if not rows:
        return []

    scored: list[tuple[str, float]] = []
    for row in rows:
        stored = embedder.bytes_to_vec(row["embedding"])
        # Cosine similarity (vectors are already L2-normalised)
        sim = float(np.dot(query_vec, stored))
        scored.append((row["content"], sim))

    scored.sort(key=lambda x: x[1], reverse=True)
    return scored[:top_k]
