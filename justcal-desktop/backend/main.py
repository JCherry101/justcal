import sys
import os

# Ensure the backend package root is on sys.path so relative imports work
# regardless of how the script is launched (e.g. from Flutter subprocess).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from services import db, embedder
from routes import tasks, documents, chat, calendar, auth, settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    # ── Startup ──
    db.init_db()
    embedder.start_loading()
    print("[BACKEND] Database initialised, embedder loading in background")
    yield
    # ── Shutdown ──
    print("[BACKEND] Shutting down")


app = FastAPI(title="JustCal Backend", version="0.1.0", lifespan=lifespan)

# Allow Flutter dev & release to reach the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount all routers
app.include_router(tasks.router)
app.include_router(documents.router)
app.include_router(chat.router)
app.include_router(calendar.router)
app.include_router(auth.router)
app.include_router(settings.router)


@app.get("/health")
def health():
    return {
        "status": "ok",
        "embedder_ready": embedder.is_ready(),
    }


if __name__ == "__main__":
    port = int(os.environ.get("JUSTCAL_PORT", "21547"))
    uvicorn.run(app, host="127.0.0.1", port=port)
