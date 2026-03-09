import os
from pathlib import Path

import fitz  # PyMuPDF
from docx import Document as DocxDocument

# Maximum file size: 50 MB
MAX_FILE_SIZE = 50 * 1024 * 1024

# PDF magic bytes: %PDF
_PDF_MAGIC = b"%PDF"
# DOCX is a ZIP archive; ZIP magic bytes
_ZIP_MAGIC = b"PK\x03\x04"


def _validate_file(path: str) -> Path:
    """Resolve the path and validate size and type."""
    resolved = Path(path).resolve()
    if not resolved.is_file():
        raise ValueError("File does not exist")

    size = resolved.stat().st_size
    if size > MAX_FILE_SIZE:
        raise ValueError(f"File too large ({size} bytes). Maximum is {MAX_FILE_SIZE} bytes.")
    if size == 0:
        raise ValueError("File is empty")

    lower = str(resolved).lower()
    with open(resolved, "rb") as f:
        header = f.read(8)

    if lower.endswith(".pdf"):
        if not header.startswith(_PDF_MAGIC):
            raise ValueError("File does not appear to be a valid PDF")
    elif lower.endswith(".docx"):
        if not header.startswith(_ZIP_MAGIC):
            raise ValueError("File does not appear to be a valid DOCX")
    else:
        raise ValueError("Unsupported file type. Only PDF and DOCX are supported.")

    return resolved


def extract_pdf_text(path: str) -> str:
    doc = fitz.open(path)
    pages = [page.get_text() for page in doc]
    doc.close()
    return "\n".join(pages)


def extract_docx_text(path: str) -> str:
    doc = DocxDocument(path)
    return "\n".join(p.text for p in doc.paragraphs)


def extract_text(path: str) -> str:
    resolved = _validate_file(path)
    lower = str(resolved).lower()
    if lower.endswith(".pdf"):
        return extract_pdf_text(str(resolved))
    elif lower.endswith(".docx"):
        return extract_docx_text(str(resolved))
    raise ValueError("Unsupported file type. Only PDF and DOCX are supported.")


CHUNK_SIZE = 800
CHUNK_OVERLAP = 150


def chunk_text(text: str) -> list[str]:
    text = text.strip()
    if not text:
        return []
    if len(text) <= CHUNK_SIZE:
        return [text]

    chunks: list[str] = []
    start = 0
    while start < len(text):
        end = min(start + CHUNK_SIZE, len(text))
        slice_ = text[start:end]
        if end < len(text):
            # Try to break at a sentence / paragraph boundary
            brk = slice_.rfind("\n")
            if brk == -1:
                brk = slice_.rfind(". ")
            if brk != -1:
                end = start + brk + 1
        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)
        start = max(end - CHUNK_OVERLAP, start + 1)
    return chunks
