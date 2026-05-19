# Lab Guide — Day 1: AI Coding Agents & Refactor InsightHub

> **Module 7 — AI-Native DevOps** · Pillar A: Develop with AI
> Thời lượng: 2.5 giờ (150 phút) · Running project: **InsightHub**

---

## Mục tiêu buổi học

Kết thúc Day 1, học viên có thể:

1. Phân biệt các loại AI Coding Agent và chọn đúng tool cho từng tình huống.
2. Vận hành Claude Code trong terminal — viết `CLAUDE.md`, chạy task refactor.
3. Refactor InsightHub v0: tách `ingestion-worker` thành service riêng + thêm Redis queue.
4. Hiểu vì sao kiến trúc async là nền tảng cho các bài Observability (Day 4).

**Daily Artifact cần nộp:** repo cá nhân có `CLAUDE.md` + 1 PR feature + `ingestion-worker` đã tách + `docker-compose` chạy được 5 service (hoặc tối thiểu 4 + worker).

---

## Chuẩn bị trước buổi (trainer kiểm tra 15 phút đầu)

- [ ] `bash scripts/verify-setup.sh` → PASS toàn bộ
- [ ] InsightHub v0 chạy được: `docker compose up --build` + `bash scripts/smoke-test.sh` PASS 6/6
- [ ] Claude Code đã cài + đăng nhập (`claude` chạy được trong terminal)
- [ ] Đã đọc bài "Building effective AI agents" của Anthropic

---

## Segment 1 — Recap & Hook (15 phút)

**Trainer trình bày:**

- AI for DevOps 2026 KHÔNG phải là gắn API vào app. Đó là tư duy 2023.
- Con số: job posting yêu cầu AI agent skill tăng **+340%** (Jan 2025 → Jan 2026); pure implementation role giảm 17%.
- Benchmark: Claude Opus 4.7 dẫn đầu SWE-bench Pro (64.3%). Coding agent giờ giải được task thật, không chỉ autocomplete.
- **Hook:** "Hôm nay các bạn sẽ không viết code refactor bằng tay. Các bạn sẽ chỉ huy một AI agent làm việc đó — và review nó như review một junior."

**Câu hỏi mở cho lớp:** Ai đã từng dùng Copilot/Cursor? Khác gì với việc "AI agent tự refactor cả module"?

---

## Segment 2 — Concept: AI Coding Agents Landscape (45 phút)

### 2.1. Ba nhóm AI Coding Agent

| Nhóm | Đại diện | Đặc điểm | Khi nào dùng |
|---|---|---|---|
| **IDE-first** | Cursor, Windsurf | Tích hợp trong editor, agent mode + tab completion | Sửa code khi đang code, exploration |
| **CLI-first** | Claude Code, Aider, Codex CLI | Chạy trong terminal, headless, scriptable | DevOps workflow, CI/CD, refactor lớn, automation |
| **Cloud / async** | Devin, Codex Cloud | Chạy nền trên cloud, nhận task qua issue/PR | Task dài, song song nhiều task |

**Trọng tâm khóa học: CLI-first (Claude Code)** — vì:
- DevOps engineer sống trong terminal.
- Scriptable → đưa vào pipeline được (Day 3).
- `CLAUDE.md` cho context bền vững giữa các phiên.

### 2.2. CLAUDE.md — "bộ nhớ dự án"

Claude Code đọc `CLAUDE.md` ở thư mục gốc mỗi phiên. File này chứa: kiến trúc, quy ước code, lệnh hay dùng, ràng buộc. Context tốt = agent làm việc chính xác hơn, ít hỏi lại.

### 2.3. Token efficiency

Claude Code dùng ít token hơn Cursor ~5.5x cho cùng task, do CLI-first không phải gửi toàn bộ editor state. Quan trọng khi tính cost (Day 6).

---

## Segment 3 — Best Practice: Làm việc với AI Agent (30 phút)

### 3.1. Vòng lặp an toàn

```
Prompt rõ ràng → Agent đề xuất → Human REVIEW → Approve → Agent thực thi → Verify
```

**KHÔNG** để agent tự apply thay đổi lớn mà không review. "Vibe-coding" vào production là anti-pattern.

### 3.2. Prompt tốt cho refactor

- Mô tả **mục tiêu** (output mong muốn), không chỉ task.
- Nêu **ràng buộc** rõ ràng ("giữ nguyên schema DB", "không đổi API contract").
- Yêu cầu agent **giải thích plan trước khi sửa**.

### 3.3. Subagents

Claude Code hỗ trợ subagent — agent con với tool scope hẹp. Nâng cao, sẽ nhắc lại Day 5.

---

## Segment 4 — Live Demo + Hands-on: Refactor InsightHub (45 phút)

> Đây là phần cốt lõi. Trainer demo trước 15 phút, học viên làm 30 phút.

### Bước 0 — Khởi tạo CLAUDE.md

```bash
cd insighthub
cp CLAUDE.md.template CLAUDE.md
claude
```

Trong phiên Claude Code:

```
/init
```

`/init` để Claude Code quét codebase và sinh `CLAUDE.md` ban đầu. Sau đó học viên chỉnh tay: bổ sung phần ràng buộc (pgvector >= 0.8.2, EMBEDDING_DIM phải khớp schema).

### Bước 1 — Để Claude Code đọc hiểu vấn đề

Prompt:

```
Đọc api/app/services/ingestion.py và api/app/routers/documents.py.
Giải thích điểm yếu kiến trúc của cách xử lý ingestion hiện tại.
Chưa sửa gì — chỉ phân tích.
```

Học viên đọc câu trả lời của agent, đối chiếu với comment cảnh báo trong code.

### Bước 2 — Refactor: tách ingestion-worker

Prompt (có sẵn trong `ingestion-worker/README.md`):

```
Tách phần ingest đồng bộ thành một ARQ worker trong thư mục ingestion-worker/.
Yêu cầu:
- Worker dùng arq, kết nối Redis qua REDIS_URL
- Tái sử dụng process_document() — KHÔNG viết lại logic chunk/embed
- API enqueue job thay vì gọi trực tiếp, trả HTTP 202
- Worker và API share cùng Docker base image, khác CMD
- process_document() dùng psycopg sync — trong ARQ worker async phải
  chạy qua run_in_executor để không block event loop
- Thêm Gauge metric insighthub_ingestion_queue_depth
Giữ nguyên schema DB. Viết Dockerfile cho worker.
Trình bày plan trước khi sửa file.
```

**Trainer nhấn mạnh:** đọc plan agent đưa ra TRƯỚC khi cho nó sửa. Đây là điểm dạy "review như review junior".

### Bước 3 — Cập nhật docker-compose

Prompt:

```
Cập nhật docker-compose.yml: thêm service redis và ingestion-worker.
Tham chiếu cấu trúc 5 service. api và worker đều cần REDIS_URL.
```

### Bước 4 — Verify

```bash
docker compose up --build
bash scripts/smoke-test.sh
```

Upload tài liệu → status phải là `pending` ngay (không block), rồi chuyển `ready` sau khi worker xử lý xong.

### Bước 5 — Thêm 1 feature nhỏ

Prompt gợi ý:

```
Thêm tính năng: API trả về cả điểm similarity của từng nguồn trong response chat,
và web hiển thị similarity bên cạnh tên file nguồn.
```

(Feature này nhỏ, có thể tùy biến — mục đích là tập làm việc với agent trên 1 thay đổi end-to-end web + api.)

---

## Segment 5 — Workshop & Support (15 phút)

- Học viên commit & push lên repo cá nhân.
- Tạo 1 PR cho feature ở Bước 5.
- Q&A, trainer hỗ trợ ai bị kẹt.

---

## Daily Artifact — Checklist nộp

| # | Artifact | Cách verify |
|---|---|---|
| 1 | `CLAUDE.md` hoàn chỉnh | File có phần kiến trúc + ràng buộc, không còn placeholder |
| 2 | `ingestion-worker/` đã có code | `worker/tasks.py` + `worker/settings.py` + `Dockerfile` |
| 3 | `docker-compose` 5 service chạy | `docker compose up` OK, `smoke-test.sh` PASS |
| 4 | 1 PR feature | Link PR trên GitHub |
| 5 | AI prompt log | Học viên lưu lại các prompt đã dùng (để Day 7 chứng minh AI-augmented) |

**Tiêu chí đạt:** artifact 1-3 bắt buộc; 4-5 nên có. Trainer chấm async qua repo.

---

## Troubleshooting

| Triệu chứng | Nguyên nhân | Xử lý |
|---|---|---|
| `claude` không chạy | Chưa đăng nhập / chưa cài | `claude login`, kiểm tra Node.js 20+ |
| Worker không nhận job | API và worker khác `REDIS_URL` | Đảm bảo cả 2 trỏ `redis://redis:6379` |
| `event loop is already running` | `process_document` sync gọi trực tiếp trong worker async | Dùng `run_in_executor` |
| Upload vẫn block | API vẫn gọi `ingest_document_sync` | Kiểm tra `documents.py` đã đổi sang `enqueue_job` |
| docker-compose lỗi build worker | Dockerfile worker thiếu deps | Worker cần arq + psycopg + pgvector + voyageai |

---

## Homework (chuẩn bị Day 2)

1. Hoàn tất refactor nếu chưa xong tại lớp.
2. Đọc spec MCP overview tại modelcontextprotocol.io (~30 phút).
3. Tạo AWS IAM user `mcp-readonly` với policy `ReadOnlyAccess`.
4. Setup kubeconfig context cho lab cluster (trainer cung cấp).

---

## Ghi chú cho Trainer

- Đáp án refactor ở `docs/reference-solutions/` — dùng để hỗ trợ học viên kẹt, KHÔNG phát trước.
- Điểm học viên hay sai nhất: quên `run_in_executor` → worker bị block. Để sẵn slide giải thích sync-trong-async.
- Nếu lớp yếu: dành thêm 10 phút Bước 0-1, rút ngắn Bước 5 (feature có thể làm thành homework).
- Nếu lớp mạnh: thử thách thêm — yêu cầu agent viết healthcheck cho worker.
