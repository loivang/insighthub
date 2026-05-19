# InsightHub — Getting Started (Student Edition)

> **Module 7: AI-Native DevOps · Running Project**
> File này là **bước đầu tiên** của bạn với InsightHub. Đọc xong → setup xong → ready Day 1.
> Thời gian: ~45-60 phút (làm 1 lần, lab thông suốt cả khoá).

---

## Tổng quan 30 giây

**InsightHub** = web app RAG Notebook (như Google NotebookLM):
- User upload tài liệu → hệ thống chunk + embed → lưu pgvector.
- Hỏi câu hỏi → retrieve + LLM generate câu trả lời.

**Bạn KHÔNG xây app từ đầu**. App code đã có sẵn. Nhiệm vụ của bạn qua **7 ngày**:

| Day | Việc làm trên InsightHub |
|---|---|
| 1 | Refactor: tách `ingestion-worker` + Redis queue. Viết `CLAUDE.md`. |
| 2 | Cấu hình MCP servers (4+). Debug qua MCP. |
| 3 | AI sinh Terraform + GitHub Actions. Deploy lên K8s. |
| 4 | Instrument Prometheus + anomaly detection + AI RCA. |
| 5 | Build Slack ChatOps bot có MCP backend. |
| 6 | Red-team với Promptfoo + LiteLLM gateway + cost dashboard. |
| 7 | Demo production-grade deployment. |

---

## 1. Trước khi clone — Pre-class checklist

Kiểm tra máy bạn đã sẵn sàng. Mỗi item phải PASS:

| # | Yêu cầu | Verify |
|---|---|---|
| 1 | macOS / Linux / Windows + WSL2 | `uname -a` |
| 2 | RAM ≥ 16GB | Activity Monitor / System Settings |
| 3 | Disk free ≥ 30GB | `df -h` |
| 4 | Docker Desktop running | `docker info` |
| 5 | Node.js 20+ | `node -v` |
| 6 | Python 3.11+ | `python3 --version` |
| 7 | Git 2.40+ | `git --version` |
| 8 | Claude Code CLI | `claude --version` |
| 9 | (Day 3+) kubectl, helm, terraform, aws-cli | `kubectl version --client && helm version && terraform -version && aws --version` |
| 10 | GitHub SSH key | `ssh -T git@github.com` |

**Cài thiếu:**
```bash
# macOS
brew install docker node@20 python@3.11 git kubectl helm terraform awscli
npm install -g @anthropic-ai/claude-code

# Linux (Debian/Ubuntu)
# Follow each tool's official install guide
```

---

## 2. Clone repo + setup môi trường

```bash
# 1. Clone (trainer cung cấp URL repo)
git clone <repo-url> insighthub
cd insighthub

# 2. Tạo .env từ template
cp .env.example .env

# (Tùy chọn) Mở .env và điền API key thật cho chất lượng tốt:
#   ANTHROPIC_API_KEY=sk-ant-...
#   VOYAGE_API_KEY=pa-...
#   EMBEDDING_PROVIDER=voyage
#
# Không điền cũng được — hệ thống chạy chế độ fallback (local embedding + extractive answer).

# 3. Verify môi trường
bash scripts/verify-setup.sh
# → Phải pass tất cả core tools. Fix mọi [FAIL] trước khi tiếp tục.
```

---

## 3. Chạy v0 lần đầu — Smoke test

```bash
# Khởi động stack (3 service: web + api + postgres)
docker compose up --build
# → Lần đầu mất 3-5 phút build image. Lần sau nhanh hơn (cached layers).

# Mở terminal khác, smoke test
bash scripts/smoke-test.sh
```

**Output mong đợi**:
```
[1] API liveness... PASS
[2] API readiness (DB)... PASS
[3] Web health... PASS
[4] Upload tài liệu mẫu... PASS
[5] Truy vấn RAG... PASS
[6] Prometheus metrics... PASS
=== Kết quả: 6 PASS / 0 FAIL ===
```

**Mở browser**:
- Web UI: http://localhost:3000
- API docs: http://localhost:8000/docs
- Metrics: http://localhost:8000/metrics

Upload sample doc → hỏi câu hỏi → thấy answer (có thể không chính xác lắm nếu dùng local fallback, NHƯNG pipeline phải end-to-end).

---

## 4. Tour codebase 5 phút

```
insighthub/
├── 📦 web/                     # Next.js 15 frontend — CHO SẴN, không sửa
├── 📦 api/                     # FastAPI gateway — CHO SẴN (Day 1 sẽ refactor 1 service)
│   ├── app/main.py             # entrypoint
│   ├── app/routers/            # /chat, /documents, /health
│   ├── app/services/           # ingestion, embeddings, llm, retrieval
│   │   └── ingestion.py        # ⚠️ Day 1 refactor TARGET
│   └── app/core/               # config, db, metrics
├── 📦 ingestion-worker/        # ⚠️ TRỐNG — Day 1 bạn TẠO
├── 📦 chatops-bot/             # ⚠️ Skeleton — Day 5 bạn hoàn thiện
├── 📦 infra/db/init.sql        # Postgres schema + pgvector + HNSW index
├── 📦 infra/                   # ⚠️ TRỐNG — Day 3 bạn sinh Terraform
├── 📦 observability/           # ⚠️ TRỐNG — Day 4 bạn thêm Prometheus rules
├── 📦 security/                # ⚠️ Day 6 — Promptfoo config
├── 📦 sample-docs/             # Tài liệu mẫu (có 1 file chứa injection cho Day 6)
├── 📦 docs/
│   ├── lab-guides/             # Hướng dẫn từng Day (mở khi đến ngày đó)
│   ├── pre-reading/            # Tài liệu đọc trước
│   └── TRAINER-SETUP.md        # (cho trainer — bạn có thể bỏ qua)
├── scripts/
│   ├── verify-setup.sh         # Check môi trường
│   ├── smoke-test.sh           # Test v0 end-to-end
│   └── verify-day-{1..7}.sh    # Verify artifact mỗi Day
├── docker-compose.yml          # v0 — 3 service
├── .env.example                # Template env vars
├── .mcp.json.template          # Day 2 — bạn copy → .mcp.json
└── CLAUDE.md                   # ⚠️ Template — Day 1 bạn hoàn thiện
```

**3 file quan trọng nhất:**

1. **`CLAUDE.md`** — "bộ não persistent" của AI agent. Day 1 bạn hoàn thiện 6 section.
2. **`api/app/services/ingestion.py`** — chứa logic ingest. Day 1 refactor target.
3. **`docker-compose.yml`** — Day 1 thêm Redis + ingestion-worker → thành 5 service.

---

## 5. Workflow hàng ngày (Day 1-6)

```
┌─────────────────────────────────────────────────────────────┐
│  Trước buổi học (đêm hôm trước, 1 giờ)                       │
│  └─ Đọc docs/pre-reading/DayN-*.md                          │
│  └─ Đọc docs/lab-guides/DayN-*.md (skim — overview)         │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  Trong buổi học (2.5h tại lớp)                              │
│  └─ Mentor giảng + demo + Q&A                                │
│  └─ Bạn follow + bắt đầu lab                                 │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  Sau buổi học (homework — 1-2h)                              │
│  └─ Hoàn thiện artifact theo docs/lab-guides/DayN            │
│  └─ Chạy `bash scripts/verify-day-N.sh`                     │
│  └─ Commit + push lên repo cá nhân                          │
│  └─ Submit qua Slack #day{N}-submissions (link PR + verify) │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  Trong vòng 24h: Trainer return rubric qua Slack DM         │
└─────────────────────────────────────────────────────────────┘
```

### Branch convention

```bash
# Mỗi Day → 1 branch
git checkout -b day1-refactor

# Sau khi hoàn thiện
git push origin day1-refactor
gh pr create --title "[Day 1] Refactor ingestion async + Redis queue" \
             --body "See ai-prompts/day1.md for AI workflow."
```

### Submission format (Slack)

```
Day 1 — <Your Name>

✓ Repo: https://github.com/<u>/insighthub
✓ CLAUDE.md: <URL>
✓ PR refactor: <URL>
✓ Prompt log: ai-prompts/day1.md
✓ Verify output:
   bash scripts/verify-day-1.sh → 7 PASS / 0 FAIL ✓
   docker compose ps → 5 service Running
```

---

## 6. Chế độ chạy: 4 mode

InsightHub hỗ trợ 4 mode provider — đổi qua `.env`, không sửa code:

### Mode A: Gemini (DEFAULT — recommend cho lab) 🌟

Free tier hào phóng. 1 key cho cả LLM + embedding.

```bash
# .env
LLM_PROVIDER=gemini
GEMINI_API_KEY=<paste-key-here>

EMBEDDING_PROVIDER=gemini
# Embedding model + dim mặc định đã set, không cần đổi
```

→ Đăng ký free tại https://aistudio.google.com/apikey (Google account đủ).
→ Quality tốt, đủ cho Day 1-7. Free tier ~1500 req/day.

### Mode B: Anthropic Claude + Voyage embedding

Premium quality. 2 keys.

```bash
LLM_PROVIDER=anthropic
ANTHROPIC_API_KEY=sk-ant-...

EMBEDDING_PROVIDER=voyage
VOYAGE_API_KEY=pa-...
```

→ Chất lượng cao nhất cho RAG. Khuyến nghị cho production demo.
→ Cost ~$15-30/khoá per student.

### Mode C: Ollama on-prem (deepseek-r1:14b) 🏢

Không cần API key. Run local — phù hợp enterprise concern data privacy.

```bash
# Khởi động với profile ollama
docker compose --profile ollama up --build

# Pull model (lần đầu ~9GB, 5-15 phút)
docker compose exec ollama ollama pull deepseek-r1:14b

# .env
LLM_PROVIDER=ollama
EMBEDDING_PROVIDER=ollama
```

→ Yêu cầu RAM ≥ 16GB. Có GPU NVIDIA tốt hơn (uncomment GPU block trong compose).
→ Chất lượng kém hơn Gemini/Claude nhưng zero cloud cost.
→ Hữu ích cho lab demo "AI on-prem" Day 6.

### Mode D: Local fallback (no API key, no Ollama)

```bash
LLM_PROVIDER=gemini      # vẫn để vậy
GEMINI_API_KEY=          # trống → fallback extractive

EMBEDDING_PROVIDER=local # hash-based deterministic
```

→ Pipeline chạy được nhưng retrieval rất kém, answer chỉ trích đoạn.
→ Chỉ dùng cho smoke test trước Day 1, KHÔNG đủ cho Day 7.

**Khuyến nghị lộ trình**:
- Day 1-7: **Mode A (Gemini)** cho 95% học viên.
- Day 6 (Security): demo thêm **Mode C (Ollama)** khi nói về data privacy.
- **Mode D** chỉ khi smoke test môi trường.

---

## 7. Cost expectations

InsightHub là **lab cá nhân** — cost ước tính per student trong 7 ngày:

| Provider | Item | Cost ước (USD) |
|---|---|---|
| Anthropic | Claude Code (Sonnet 4.6) + RAG generation | $15-30 |
| Anthropic | Embedding via Claude (nếu dùng) | ~$1 |
| Voyage AI | Embedding (voyage-3.5) | ~$2 |
| AWS (Day 3+) | RDS db.t3.small + ElastiCache + EKS namespace | $10-20 |
| GitHub | Actions free tier | $0 |
| Grafana Cloud | Free tier | $0 |
| **TỔNG** |  | **$30-55** |

**Tip**:
- Set Anthropic Console spend limit $50/month ngay từ Day 1.
- Day 3 dùng `db.t3.small` single-AZ, single replica.
- Day 6 setup LiteLLM gateway + budget cap để control.

---

## 8. Troubleshooting nhanh

| Problem | Fix |
|---|---|
| `docker compose up` báo port conflict | Stop other apps using 8000, 5432, 3000; `docker compose down` |
| `EMBEDDING_DIM mismatch` error trong logs | `.env` `EMBEDDING_DIM` phải khớp `VECTOR(n)` trong `infra/db/init.sql` |
| Web/API không thấy nhau | `API_INTERNAL_URL=http://api:8000` (dùng service name, không localhost) |
| `pgvector extension not found` | `docker compose down -v` (xóa volume cũ) + `docker compose up` (init lại) |
| Upload PDF lỗi extract | PDF có thể là image-only → cần OCR. Thử file .md/.txt trước. |
| Chat answer "Không tìm thấy" | Embedding mode local kém — chuyển sang `voyage` với API key |
| `claude` không chạy | `npm install -g @anthropic-ai/claude-code` + Node 20+; `claude login` |

**Còn vướng?** Xem [`docs/STUDENT-FAQ.md`](docs/STUDENT-FAQ.md) hoặc hỏi Slack `#help`.

---

## 9. Tham khảo nhanh — Endpoints

### API (FastAPI, port 8000)

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Service info |
| `GET` | `/healthz` | Liveness probe |
| `GET` | `/readyz` | Readiness (check DB) |
| `GET` | `/metrics` | Prometheus metrics |
| `GET` | `/docs` | OpenAPI Swagger UI |
| `POST` | `/documents` | Upload file (multipart) |
| `GET` | `/documents` | List all documents |
| `DELETE` | `/documents/{id}` | Delete document |
| `POST` | `/chat` | RAG query `{question, top_k?}` |

### Web (Next.js, port 3000)

| Path | Mô tả |
|---|---|
| `/` | Upload UI + Chat UI |
| `/api/health` | Liveness probe |
| `/api/documents` | Proxy → backend |
| `/api/proxy` | Generic proxy → backend |

### Database (Postgres, port 5432)

```bash
docker compose exec postgres psql -U insighthub -d insighthub

# Quick queries:
SELECT * FROM documents ORDER BY created_at DESC LIMIT 5;
SELECT count(*) FROM chunks;
SELECT extversion FROM pg_extension WHERE extname = 'vector';
```

---

## 10. Khi nào đọc tài liệu nào

| Vấn đề bạn đang gặp | Đọc |
|---|---|
| "Lý thuyết Day N — vì sao thế?" | `docs/pre-reading/DayN-*.md` |
| "Day N tôi phải làm gì?" | `docs/lab-guides/DayN-*.md` |
| "Setup tool này thế nào?" | `tools-handbook-v3/DayN-*.md` (trainer cung cấp) |
| "Yêu cầu nộp + rubric?" | `Running-Project-Specification-Student.md` (trainer cung cấp) |
| "Lỗi này fix thế nào?" | `docs/STUDENT-FAQ.md` |
| "Workflow daily submission?" | `docs/DAILY-WORKFLOW.md` |

---

## 11. Tự kiểm tra trước Day 1

Trả lời ✅ trước khi đến Day 1:

```
[ ] bash scripts/verify-setup.sh → all PASS
[ ] docker compose up → 3 service Running
[ ] bash scripts/smoke-test.sh → 6 PASS / 0 FAIL
[ ] Mở http://localhost:3000 → upload sample doc → hỏi câu hỏi → có answer
[ ] Đã đọc docs/pre-reading/Day1-AI-Coding-Agents.md
[ ] claude --version works + claude login OK
[ ] Anthropic Console: spend limit $50/month đã set
[ ] GitHub repo cá nhân tạo xong + add SSH key
[ ] Slack workspace InsightHub Lab joined (#help, #day1-submissions...)
```

Nếu 9/9 ✅ → ready Day 1.

---

## Lời nhắn

7 ngày sắp tới là một hành trình thực tế. Bạn sẽ:
- **Refactor** một codebase production-like bằng AI agent (Day 1).
- **Sinh Terraform + pipeline** bằng AI và policy gate (Day 3).
- **Build observability stack** với AI RCA (Day 4).
- **Build ChatOps bot** an toàn cho production (Day 5).
- **Red team** chính app mình + build cost discipline (Day 6).

Khác biệt giữa "vibe-coder" và "AI-native engineer" sau Module 7:
- Vibe-coder: AI bảo gì làm nấy.
- AI-native: hiểu code AI sinh, kiểm tra mỗi step, kiểm soát cost.

**Hẹn gặp ở Day 1.** 🚀

---

*Getting Started v3.0 · InsightHub Running Project · Module 7 AI-Native DevOps*
