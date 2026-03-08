from pydantic import BaseModel


class Task(BaseModel):
    id: str
    title: str
    deadline: str
    priority: str
    description: str
    synced: bool = False


class Milestone(BaseModel):
    id: str
    task_id: str
    title: str
    due_date: str
    kind: str  # "start" | "draft" | "review" | "final"


class Document(BaseModel):
    id: str
    filename: str
    ingested_at: str
    chunk_count: int
    task_count: int


class ChatMessage(BaseModel):
    role: str  # "user" | "assistant"
    content: str
