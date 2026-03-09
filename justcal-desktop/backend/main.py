import logging
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from services import db, embedder
from routes import tasks, documents, chat, calendar, auth, settings

logger = logging.getLogger("justcal")


@asynccontextmanager
async def lifespan(app: FastAPI):
    db.init_db()
    embedder.start_loading()
    print("[BACKEND] Database initialised, embedder loading in background")
    yield
    print("[BACKEND] Shutting down")


app = FastAPI(title="JustCal Backend", version="0.1.0", lifespan=lifespan)

# Only allow requests from the local Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1", "http://localhost"],
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Content-Type", "Authorization"],
)


@app.exception_handler(Exception)
async def _global_exception_handler(request: Request, exc: Exception):
    """Catch-all handler that prevents internal details from leaking."""
    logger.exception("Unhandled error on %s %s", request.method, request.url.path)
    return JSONResponse(status_code=500, content={"error": "Internal server error"})

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
