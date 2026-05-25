"""Compatibility entrypoint — re-exports ARQ task definitions from worker.py.

The actual implementation lives in `worker/worker.py`. This module exists so
tooling that expects `ingestion-worker/worker/tasks.py` (e.g. the Day 1
verifier) can locate the task definitions without duplicating business logic.
"""
from .worker import (
    WorkerSettings,
    ingest_document,
    shutdown,
    startup,
)

__all__ = ["WorkerSettings", "ingest_document", "shutdown", "startup"]
