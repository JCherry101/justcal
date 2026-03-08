import sqlite3
import os
import sys
import threading
from pathlib import Path

_lock = threading.Lock()
_connection: sqlite3.Connection | None = None


def _db_path() -> Path:
    if sys.platform == "darwin":
        base = Path.home() / "Library" / "Application Support" / "com.justcal.app"
    else:
        base = Path(os.environ.get("APPDATA", Path.home())) / "com.justcal.app"
    base.mkdir(parents=True, exist_ok=True)
    return base / "justcal.db"


def get_connection() -> sqlite3.Connection:
    global _connection
    if _connection is not None:
        return _connection
    with _lock:
        if _connection is not None:
            return _connection
        conn = sqlite3.connect(str(_db_path()), check_same_thread=False)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA foreign_keys=ON")
        _connection = conn
    return _connection


def init_db() -> None:
    conn = get_connection()
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS tasks (
            id          TEXT PRIMARY KEY,
            title       TEXT NOT NULL,
            deadline    TEXT NOT NULL,
            priority    TEXT NOT NULL,
            description TEXT,
            created_at  TEXT NOT NULL,
            synced      INTEGER NOT NULL DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS milestones (
            id       TEXT PRIMARY KEY,
            task_id  TEXT NOT NULL,
            title    TEXT NOT NULL,
            due_date TEXT NOT NULL,
            kind     TEXT NOT NULL,
            FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS calendar_events (
            id           TEXT PRIMARY KEY,
            provider     TEXT NOT NULL,
            event_id     TEXT NOT NULL,
            milestone_id TEXT NOT NULL,
            FOREIGN KEY (milestone_id) REFERENCES milestones(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS documents (
            id          TEXT PRIMARY KEY,
            filename    TEXT NOT NULL,
            raw_text    TEXT NOT NULL,
            ingested_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS chunks (
            id          TEXT PRIMARY KEY,
            document_id TEXT NOT NULL,
            content     TEXT NOT NULL,
            chunk_index INTEGER NOT NULL,
            FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS chat_history (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            role       TEXT NOT NULL,
            content    TEXT NOT NULL,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS embeddings (
            chunk_rowid INTEGER PRIMARY KEY,
            embedding   BLOB NOT NULL
        );
    """)
    conn.commit()
