import fitz  # PyMuPDF
from docx import Document as DocxDocument


def extract_pdf_text(path: str) -> str:
    doc = fitz.open(path)
    pages = [page.get_text() for page in doc]
    doc.close()
    return "\n".join(pages)


def extract_docx_text(path: str) -> str:
    doc = DocxDocument(path)
    return "\n".join(p.text for p in doc.paragraphs)


def extract_text(path: str) -> str:
    lower = path.lower()
    if lower.endswith(".pdf"):
        return extract_pdf_text(path)
    elif lower.endswith(".docx"):
        return extract_docx_text(path)
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
