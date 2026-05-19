# ingestion-worker

> **⚠️ Thư mục này gần như TRỐNG ở v0 — đây là CHỦ ĐÍCH.**

## Bối cảnh (Day 1 — AI Coding Agents)

Ở InsightHub v0, việc xử lý tài liệu (chunk → embed → lưu pgvector) chạy
**đồng bộ ngay trong API request handler** (`api/app/services/ingestion.py` →
`ingest_document_sync`).

Đây là điểm yếu kiến trúc cố ý để học viên thực hành refactor bằng AI:

| Vấn đề ở v0 | Hệ quả |
|---|---|
| Ingest đồng bộ trong API | Upload file lớn → request block / timeout |
| Không có queue | Không buffer được burst upload |
| Không scale worker riêng | API và ingestion dùng chung tài nguyên |
| Không retry | Embed lỗi 1 lần là mất luôn |
| Không có metric queue depth | Day 4 không có gì để observe |

## Bài tập Day 1

Dùng **Claude Code** (hoặc Cursor) refactor:

1. Tạo worker dùng **ARQ** (async Redis queue — chuẩn 2026 cho LLM workload).
2. Di chuyển `process_document()` từ `api/app/services/ingestion.py` sang đây.
   Hàm này đã được viết sao cho **tái sử dụng nguyên vẹn** — chỉ đổi cách gọi.
3. Sửa `api/app/routers/documents.py`: thay `ingest_document_sync(...)` bằng
   `redis.enqueue_job("ingest_document", document_id, filename, content)`.
4. API trả về `202 Accepted` ngay, status tài liệu = `pending`.
5. Worker xử lý xong → cập nhật status = `ready`.
6. Thêm metric `insighthub_ingestion_queue_depth` (Gauge) — Day 4 cần.

## Gợi ý prompt cho Claude Code

```
Đọc api/app/services/ingestion.py và api/app/routers/documents.py.
Tách phần ingest đồng bộ thành một ARQ worker trong thư mục ingestion-worker/.
Yêu cầu:
- Worker dùng arq, kết nối Redis qua REDIS_URL
- Tái sử dụng process_document() — không viết lại logic chunk/embed
- API enqueue job thay vì gọi trực tiếp, trả 202
- Worker và API share cùng Docker base image, khác CMD
- Thêm Gauge metric queue depth
Giữ nguyên schema DB. Viết Dockerfile cho worker.
```

## Kết quả mong đợi sau Day 1

```
ingestion-worker/
├── worker/
│   ├── __init__.py
│   ├── settings.py      # ARQ WorkerSettings
│   └── tasks.py         # ingest_document task — gọi process_document()
├── requirements.txt
├── Dockerfile
└── README.md            # file này
```

Kiến trúc sau refactor (đã có trong sheet "Running Project" của syllabus):

```
web → api → (enqueue) → redis → ingestion-worker → postgres/pgvector
```
