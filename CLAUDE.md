# CLAUDE.md — InsightHub

## Dự án

InsightHub — RAG Notebook. Người dùng upload tài liệu, hỏi đáp dựa trên tài liệu.

## Kiến trúc

Ingestion chạy **async** qua Redis + ARQ worker (Day 1 đã hoàn thành). Diagram dưới phản ánh hiện trạng.

```
web (Next.js 15)  ──►  api (FastAPI)  ──►  redis (queue)  ──►  ingestion-worker (ARQ)
                            │                                          │
                            └──────────────► postgres (pgvector) ◄──────┘
```

- **web** — Next.js 15 App Router, standalone output, gọi `api` qua `API_INTERNAL_URL`.
- **api** — FastAPI, psycopg3 async. `POST /documents` chỉ enqueue, không xử lý.
- **ingestion-worker** — ARQ worker, consume queue `arq:queue:ingestion`. Task `ingest_document` là wrapper mỏng gọi `ingest_document_sync()` từ `api/app/services/ingestion.py` qua thread executor — không nhân bản logic chunk/embed/store.
- **redis** — 7-alpine, dùng cho ARQ queue + job state. Không dùng làm cache trong v1.
- **postgres** — PostgreSQL 16 + pgvector 0.8.2. Schema ở `infra/db/init.sql`.

## API contract (must preserve)

`POST /documents` — multipart upload:
- Response: `202 Accepted` với `{ "document_id": int, "status": "queued" }`
- KHÔNG block đợi embedding. Trả về ngay sau khi enqueue ARQ job.

`GET /documents/{id}` — trả `status ∈ {queued, processing, ready, failed}`.

**Ghi chú trạng thái (Day 1):** API trả `status="queued"` ngay sau enqueue, nhưng DB lưu nội bộ `status='pending'` — CHECK constraint trong `init.sql` chỉ cho phép `pending|ready|failed`, nên Day 1 không migrate schema. `pending` (nội bộ) ≡ `queued` (public). Trạng thái `processing` chưa implement; cần migration để thêm.

Web frontend poll theo field `status` — sửa contract = break UI.

## Quy ước code

<!-- Học viên điền, ví dụ: -->
- Python: tuân theo PEP 8, dùng type hints
- Commit message: conventional commits (feat:, fix:, refactor:...)
- Không hardcode secrets — luôn dùng biến môi trường

## Lệnh thường dùng

```bash
# Full stack (web + api + worker + redis + postgres)
docker compose up --build

# Iterate trên api (postgres + redis chạy nền)
docker compose up -d postgres redis
docker compose up --build api

# Logs theo service
docker compose logs -f api
docker compose logs -f ingestion-worker

# Quan sát queue
docker compose exec redis redis-cli LLEN arq:queue:ingestion

# Reset DB — destructive, xoá pgdata volume
docker compose down -v && docker compose up --build
```

## Lưu ý quan trọng cho AI agent

- `EMBEDDING_DIM` env phải khớp `VECTOR(n)` trong `infra/db/init.sql`. Đổi một bên = phải migrate.
- `pgvector >= 0.8.2` (CVE fix — không downgrade).
- `process_document()` phải **idempotent**: gọi lại với cùng `document_id` không được tạo chunk trùng (worker có thể retry).
- ARQ retry tối đa 3 lần với exponential backoff. Lỗi non-retriable (file corrupt, embedding API 4xx) phải set status=`failed` thay vì retry vô hạn.
- Đừng import chéo giữa `api.app.*` và `ingestion_worker.*` — share code qua `api/app/services/ingestion.py` (xem docstring).
- Không có migration framework: `infra/db/init.sql` load qua docker-entrypoint. Đổi schema = phải `down -v` (mất data dev).

## Việc đang làm / TODO

<!-- Học viên cập nhật theo tiến độ 7 ngày -->
- [x] Day 1: tách ingestion-worker, thêm Redis
- [ ] Day 2: cấu hình MCP servers
- [ ] Day 3: Terraform + CI/CD pipeline
- [ ] Day 4: observability + anomaly detection
- [ ] Day 5: ChatOps bot
- [ ] Day 6: security hardening + cost monitoring
- [ ] Day 7: hoàn thiện + demo
