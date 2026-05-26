# CLAUDE.md — TEMPLATE

> Day 1: học viên hoàn thiện file này. Đây chỉ là khung gợi ý.
> CLAUDE.md là "bộ nhớ dự án" — Claude Code đọc file này mỗi phiên làm việc,
> nên context tốt = AI agent làm việc chính xác hơn.

## Dự án

InsightHub — RAG Notebook. Người dùng upload tài liệu, hỏi đáp dựa trên tài liệu.

## Kiến trúc

<!-- Học viên điền: mô tả các service, mối quan hệ. Cập nhật sau refactor Day 1. -->

- web: Next.js 15, App Router, standalone output
- api: FastAPI, psycopg3 + pgvector
- ingestion-worker: <!-- TRỐNG ở v0 — mô tả sau khi tách Day 1 -->
- redis: <!-- thêm Day 1 -->
- postgres: PostgreSQL 16 + pgvector 0.8.2

## Quy ước code

<!-- Học viên điền, ví dụ: -->
- Python: tuân theo PEP 8, dùng type hints
- Commit message: conventional commits (feat:, fix:, refactor:...)
- Không hardcode secrets — luôn dùng biến môi trường

## Lệnh thường dùng

```bash
docker compose up --build      # chạy toàn bộ stack
docker compose logs -f api     # xem log api
# <học viên bổ sung khi học các buổi sau>
```

## Lưu ý quan trọng cho AI agent

<!-- Học viên điền các ràng buộc, ví dụ: -->
- EMBEDDING_DIM phải khớp VECTOR(n) trong infra/db/init.sql
- pgvector phải >= 0.8.2 (lý do bảo mật)
- process_document() phải idempotent (worker có thể retry)

## Việc đang làm / TODO

<!-- Học viên cập nhật theo tiến độ 7 ngày -->
- [ ] Day 1: tách ingestion-worker, thêm Redis
- [ ] Day 2: cấu hình MCP servers
- [ ] Day 3: Terraform + CI/CD pipeline
- [ ] Day 4: observability + anomaly detection
- [ ] Day 5: ChatOps bot
- [ ] Day 6: security hardening + cost monitoring
- [ ] Day 7: hoàn thiện + demo
