# InsightHub ingestion-worker — ARQ worker (Day 1 Step 2)
#
# Build context is the repo root (set in docker-compose.yml) so this image can
# COPY api/app — the worker imports `app.services.ingestion` directly, per
# CLAUDE.md's "share code qua api/app/services/ingestion.py".
FROM python:3.12-slim AS base
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
WORKDIR /app

FROM base AS deps
COPY api/requirements.txt /tmp/api-requirements.txt
COPY ingestion-worker/requirements.txt /tmp/worker-requirements.txt
RUN pip install --no-cache-dir -r /tmp/api-requirements.txt -r /tmp/worker-requirements.txt

FROM base AS runtime
RUN groupadd --system --gid 1001 appuser \
    && useradd --system --uid 1001 --gid appuser appuser
COPY --from=deps /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=deps /usr/local/bin /usr/local/bin
COPY --chown=appuser:appuser api/app ./app
COPY --chown=appuser:appuser ingestion-worker/worker ./worker
USER appuser
CMD ["arq", "worker.worker.WorkerSettings"]
