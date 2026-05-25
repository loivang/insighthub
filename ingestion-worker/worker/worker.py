"""ingestion-worker — ARQ worker (Day 1 Step 2).

Consumes the `arq:queue:ingestion` queue and runs the existing synchronous
`ingest_document_sync()` from api/app/services/ingestion.py. The function is
called inside a thread executor because psycopg uses a synchronous pool.

`ingest_document_sync` already sets `status='failed'` and re-raises on error,
which lets ARQ apply its retry/backoff (max_tries=3). The idempotency guard
inside `process_document` clears stale chunks before re-inserting, so retries
don't duplicate data.
"""
import asyncio
import functools
import logging
import os

from arq.connections import RedisSettings

from app.services.ingestion import ingest_document_sync

logger = logging.getLogger("ingestion_worker")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)

REDIS_URL = os.environ.get("REDIS_URL", "redis://redis:6379/0")
QUEUE_NAME = "arq:queue:ingestion"


async def ingest_document(
    ctx: dict,
    document_id: int,
    filename: str,
    content: bytes,
) -> int:
    loop = asyncio.get_running_loop()
    chunks_made = await loop.run_in_executor(
        None,
        functools.partial(ingest_document_sync, document_id, filename, content),
    )
    logger.info("ingest_document %s done: %d chunks", document_id, chunks_made)
    return chunks_made


async def startup(ctx: dict) -> None:
    logger.info("ingestion-worker started, listening on queue=%s", QUEUE_NAME)


async def shutdown(ctx: dict) -> None:
    logger.info("ingestion-worker shutting down")


class WorkerSettings:
    functions = [ingest_document]
    redis_settings = RedisSettings.from_dsn(REDIS_URL)
    queue_name = QUEUE_NAME
    max_tries = 3
    on_startup = startup
    on_shutdown = shutdown
