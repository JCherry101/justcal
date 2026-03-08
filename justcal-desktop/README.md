# JustCal

AI-powered scheduling assistant — desktop app built with **Flutter** (frontend) and **Python/FastAPI** (backend).

Ingest documents (PDF, DOCX), extract tasks via Google Gemini, sync to Google Calendar, and chat with an AI assistant that has RAG context over your documents.

## Architecture

- **Frontend**: Flutter desktop (Windows & macOS)
- **Backend**: FastAPI running on `127.0.0.1:21547`, spawned as a subprocess by the Flutter app
- **Embeddings**: `sentence-transformers` (`all-MiniLM-L6-v2`)
- **Database**: SQLite (`~/.justcal/justcal.db`)
- **AI**: Google Gemini API (task extraction + RAG chat)

## Prerequisites

- [Python 3.10+](https://www.python.org/downloads/)
- [Flutter SDK 3.2+](https://docs.flutter.dev/get-started/install) with desktop support enabled

## Setup

### Backend

```bash
cd backend
python -m venv .venv

# Windows
.venv\Scripts\activate
# macOS/Linux
source .venv/bin/activate

pip install -r requirements.txt
```

### Flutter

```bash
# Generate platform runners (first time only)
flutter create --platforms=windows,macos .

flutter pub get
```

## Run

### Development (separate processes)

```bash
# Terminal 1 — backend
cd backend
python main.py

# Terminal 2 — frontend
flutter run -d windows   # or -d macos
```

### Production build

```bash
flutter build windows   # or: flutter build macos
```

The built app automatically spawns and manages the Python backend process.

## Project Structure

```
backend/           Python FastAPI backend
  main.py          App entry point (port 21547)
  models.py        Pydantic data models
  routes/          API route modules
  services/        Business logic (db, embedder, auth, RAG, etc.)
lib/               Flutter frontend
  main.dart        App entry point
  models/          Dart data models
  screens/         Screen widgets
  services/        API client + backend process manager
  theme/           App theme + colors
  widgets/         Reusable UI components
```
