"""
InsightHub API — Documents router

Upload pipeline (Day 1, async): persist metadata → enqueue ARQ job → return 202.
Worker (ingestion-worker) consumes the queue and runs the existing
`ingest_document_sync` from `app.services.ingestion`.
"""
import logging

from fastapi import APIRouter, HTTPException, Request, UploadFile

from app.core.db import get_conn
from app.core.metrics import documents_total

logger = logging.getLogger("insighthub.routers.documents")
router = APIRouter(prefix="/documents", tags=["documents"])

ALLOWED_EXT = (".txt", ".md", ".pdf")
MAX_SIZE_MB = 10
INGESTION_QUEUE = "arq:queue:ingestion"


@router.post("", status_code=202)
async def upload_document(request: Request, file: UploadFile):
    if not file.filename or not file.filename.lower().endswith(ALLOWED_EXT):
        raise HTTPException(400, f"Chỉ chấp nhận: {', '.join(ALLOWED_EXT)}")

    content = await file.read()
    if len(content) > MAX_SIZE_MB * 1024 * 1024:
        raise HTTPException(413, f"File vượt quá {MAX_SIZE_MB}MB")

    # DB CHECK constraint allows only ('pending','ready','failed'); 'pending' is
    # the on-disk representation of the public 'queued' state.
    with get_conn() as conn:
        row = conn.execute(
            "INSERT INTO documents (filename, status) VALUES (%s, 'pending') RETURNING id",
            (file.filename,),
        ).fetchone()
        document_id = row[0]

    await request.app.state.arq_pool.enqueue_job(
        "ingest_document",
        document_id,
        file.filename,
        content,
        _queue_name=INGESTION_QUEUE,
    )

    return {"document_id": document_id, "status": "queued"}


@router.get("")
async def list_documents():
    with get_conn() as conn:
        rows = conn.execute(
            "SELECT id, filename, status, chunk_count, created_at "
            "FROM documents ORDER BY created_at DESC"
        ).fetchall()

    # Cập nhật gauge cho Prometheus
    counts: dict[str, int] = {}
    for r in rows:
        counts[r[2]] = counts.get(r[2], 0) + 1
    for status in ("pending", "ready", "failed"):
        documents_total.labels(status=status).set(counts.get(status, 0))

    return [
        {
            "id": r[0],
            "filename": r[1],
            "status": r[2],
            "chunk_count": r[3],
            "created_at": r[4].isoformat() if r[4] else None,
        }
        for r in rows
    ]


@router.delete("/{document_id}", status_code=204)
async def delete_document(document_id: int):
    with get_conn() as conn:
        result = conn.execute(
            "DELETE FROM documents WHERE id = %s RETURNING id", (document_id,)
        ).fetchone()
    if result is None:
        raise HTTPException(404, "Không tìm thấy tài liệu")
