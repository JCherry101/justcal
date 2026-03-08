import threading
import numpy as np

_model = None
_ready = threading.Event()


def _load_model() -> None:
    global _model
    try:
        from sentence_transformers import SentenceTransformer
        print("[EMBEDDER] Loading all-MiniLM-L6-v2 ...")
        _model = SentenceTransformer("all-MiniLM-L6-v2")
        print("[EMBEDDER] Model loaded successfully")
    except Exception as e:
        print(f"[EMBEDDER] Failed to load model: {e}")
    finally:
        _ready.set()


def start_loading() -> None:
    """Start loading the embedding model in a background thread."""
    t = threading.Thread(target=_load_model, daemon=True)
    t.start()


def is_ready() -> bool:
    return _ready.is_set()


def embed_text(text: str, timeout: float = 120.0) -> list[float]:
    """Return a 384-dim embedding vector for *text*.

    Blocks up to *timeout* seconds waiting for the model to finish loading.
    """
    if not _ready.wait(timeout=timeout):
        raise RuntimeError("Embedder not ready after timeout")
    if _model is None:
        raise RuntimeError("Embedding model failed to load")
    vec = _model.encode(text, normalize_embeddings=True)
    return vec.tolist()


def embed_batch(texts: list[str], timeout: float = 120.0) -> list[list[float]]:
    """Embed multiple texts efficiently in one call."""
    if not _ready.wait(timeout=timeout):
        raise RuntimeError("Embedder not ready after timeout")
    if _model is None:
        raise RuntimeError("Embedding model failed to load")
    vecs = _model.encode(texts, normalize_embeddings=True, batch_size=32)
    return vecs.tolist()


# ── numpy helpers for cosine similarity search ──


def vec_to_bytes(v: list[float]) -> bytes:
    return np.array(v, dtype=np.float32).tobytes()


def bytes_to_vec(b: bytes) -> np.ndarray:
    return np.frombuffer(b, dtype=np.float32)
