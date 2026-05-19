# Running Project Specification — InsightHub

> **Module 7 · AI-Native DevOps · v3.0 Final**  
> Student Edition · Cho học viên · Single source-of-truth cho 7 ngày    
> Trainer: Trần Mạnh Cong · Tháng 5/2026

---

## Mục lục

**Phần 1 — Foundations**
1. [Giới thiệu Running Project](#1-giới-thiệu-running-project)
2. [InsightHub — Project Architecture](#2-insighthub--project-architecture)
3. [Pass Criteria & Rubric tổng](#3-pass-criteria--rubric-tổng)
4. [Submission & Grading Protocol](#4-submission--grading-protocol)

**Phần 2 — Daily Specifications**

5. [Day 1 — AI Coding Agent Refactor](#5-day-1--ai-coding-agent-refactor)
6. [Day 2 — MCP Protocol Integration](#6-day-2--mcp-protocol-integration)
7. [Day 3 — AI-Powered IaC & Pipeline](#7-day-3--ai-powered-iac--pipeline)
8. [Day 4 — AIOps + MLOps Overview](#8-day-4--aiops--mlops-overview)
9. [Day 5 — ChatOps Bot & Incident Response](#9-day-5--chatops-bot--incident-response)
10. [Day 6 — Security, Governance & FinOps](#10-day-6--security-governance--finops)
11. [Day 7 — Showcase & Final State](#11-day-7--showcase--final-state)

**Phần 3 — References**

12. [Self-Evaluation Form](#12-self-evaluation-form)
13. [Continued Learning — 4 Roadmaps](#13-continued-learning--4-roadmaps)
14. [Glossary](#14-glossary)

---

# Phần 1 — Foundations

## 1. Giới thiệu Running Project

### 1.1. Running Project là gì

**InsightHub** là một **web app RAG Notebook** (giống Google NotebookLM):
- Upload tài liệu (PDF, TXT, MD).
- Hệ thống chunk + embed → lưu vào pgvector.
- Hỏi câu hỏi → retrieve + LLM generate câu trả lời.

Đây là **running project** xuyên suốt 7 ngày của Module 7. Bạn nhận **v0 đã chạy được** từ trainer, qua mỗi ngày bạn **DevOps-hóa** app này thành **production-grade deployment**.

### 1.2. Mô hình học — Solo Tracks

| | Áp dụng cho khoá này |
|---|---|
| **Học viên KHÔNG** | Code feature mới, design architecture từ đầu, làm việc theo nhóm |
| **Học viên CÓ** | Fork v0, refactor (Day 1), containerize, deploy, observe, secure, cost-optimize |
| **Khác biệt junior/senior** | KHÔNG ở "ai code đẹp hơn", MÀ ở "ai DevOps engineering tốt hơn" |
| **Solo tracks** | 15 học viên làm **độc lập**, không chia nhóm |

→ Giải bài toán **input đầu vào không đều**: junior + senior đều có artifact chạy được, được chấm fair.

### 1.3. AI-Augmented, không AI-Replaced

**MỌI** task qua 7 ngày đều có AI agent tham gia. NHƯNG:

- AI tăng tốc, KHÔNG thay thế phán đoán kỹ thuật.
- Human review code AI sinh — **không** "vibe-coding".
- **AI prompt log bắt buộc submit** (chứng minh AI-augmented).
- Day 7 Q&A: bạn phải giải thích được code của mình → phân biệt "hiểu" vs "vibe code".

### 1.4. Daily Increment xuyên suốt

Day N artifact **PHẢI** build trên Day N-1:

- Day 1 refactor async → Day 4 observe queue depth (chỉ có queue khi async).
- Day 2 MCP servers → Day 5 ChatOps bot dùng cùng MCP backend.
- Day 3 deploy K8s → Day 4 instrument cluster.
- Day 4 anomaly → Day 5 bot query anomaly.

**Không skip Day**. Skip 1 ngày → mất foundation cho Day sau.

### 1.5. 7 Daily Artifacts Overview

| Day | Topic | Artifact chính | Rubric Dimension |
|---|---|---|---|
| 1 | AI Coding Agents | Repo + CLAUDE.md + PR refactor + ingestion-worker tách | AI-Augmented Code Quality (12%) |
| 2 | MCP Protocol | `.mcp.json` 4+ servers + debug session log | (foundation cho Dim 1, 4, 5) |
| 3 | AI IaC & Pipeline | Terraform module + GitHub Actions + InsightHub LIVE | IaC by AI (13%) + CI/CD by AI (13%) |
| 4 | AIOps + MLOps Overview | Grafana dashboard + anomaly + AI RCA + MLOps notes | Observability & AIOps (13%) |
| 5 | ChatOps Bot | Slack bot live + audit log | ChatOps Bot (12%) |
| 6 | Security + FinOps | Promptfoo no-HIGH + threat model + cost dashboard | Security (12%) + FinOps (7%) |
| 7 | Showcase | Final state + screencast + (optional) demo | Daily Checkpoint (18%) tổng |

---

## 2. InsightHub — Project Architecture

### 2.1. Architecture v0 (trước Day 1)

**3 services, ingestion sync trong api (cố ý điểm yếu kiến trúc — Day 1 sẽ fix):**

```
┌─────────────┐       ┌───────────────────────┐       ┌──────────────────┐
│  web        │──────>│   api (FastAPI)       │──────>│  postgres        │
│  (Next.js)  │       │   ├─ /chat            │       │  + pgvector      │
│             │       │   ├─ /upload (SYNC!)  │       │  ├─ metadata     │
└─────────────┘       │   │   chunk+embed     │       │  └─ vectors      │
                      │   │   store           │       └──────────────────┘
                      │   └────────────────────│
                      └───────────────────────┘
                              ▲
                              │ LLM API call
                              ▼
                       Anthropic Claude
                       (Generation + Embedding)
```

**Vấn đề cố ý của v0:**
- Upload file lớn → request block (60s timeout).
- Không có queue → không observe được background work (Day 4 mất feature).
- Không scale worker độc lập.

### 2.2. Architecture v1 (sau Day 1 refactor)

**5 services, async với Redis queue:**

```
web (Next.js) → api (FastAPI) → enqueue → redis → ingestion-worker → postgres+pgvector
                  ↓                                         ↓
              /chat retrieve                         chunk + embed + store
                  ↓
              Anthropic API (generation + embedding)
```

### 2.3. Production state (sau Day 3 deploy)

Same architecture nhưng **deployed on EKS**:

```
EKS namespace: insighthub-<env>
├── Deployment: web                + Service
├── Deployment: api                + Service + HPA + Ingress (TLS)
├── Deployment: ingestion-worker
└── Helm values + ConfigMap + Secret

Managed services (provisioned bằng Terraform):
├── RDS PostgreSQL 16 + pgvector ext
├── ElastiCache Redis 7
└── IAM roles for service accounts (IRSA)
```

### 2.4. Tech Stack

| Layer | Tech |
|---|---|
| Frontend | Next.js 14 (React) |
| API | FastAPI 0.110 (Python 3.11) |
| Worker | Python + ARQ |
| Queue | Redis 7 |
| Database | PostgreSQL 16 + pgvector 0.8 |
| LLM | Claude Sonnet 4.6 (chat), text-embedding-3-small (embed) |

### 2.5. Repository Structure

```
insighthub/
├── README.md                       # Project overview
├── CLAUDE.md                       # ← Bạn viết Day 1 (6 sections)
├── .mcp.json                       # ← Bạn config Day 2 (4+ servers)
├── docker-compose.yml              # v0: 3 service; v1: 5 service
├── .env.example                    # Template env vars
├── .gitignore
│
├── web/                            # Next.js (cho sẵn, không sửa)
├── api/                            # FastAPI (cho sẵn, refactor Day 1)
│   ├── app/
│   │   ├── main.py
│   │   ├── routers/
│   │   ├── services/               # ← Refactor Day 1: tách ingestion ra
│   │   └── core/metrics.py         # ← Prometheus metrics (cho sẵn cho Day 4)
│   ├── tests/
│   └── Dockerfile
│
├── ingestion-worker/               # ← TRỐNG ở v0, BẠN TẠO Day 1
│   ├── worker.py
│   ├── requirements.txt
│   └── Dockerfile
│
├── infra/                          # ← TRỐNG, BẠN sinh Day 3
│   ├── main.tf
│   ├── modules/
│   └── policies/                   # Conftest Rego
│
├── .github/workflows/              # ← TRỐNG, BẠN sinh Day 3
│
├── observability/                  # ← Day 4
│   ├── prometheus-rules.yaml
│   ├── grafana-dashboards/
│   └── alerting/
│
├── chatops-bot/                    # ← Day 5 (skeleton có sẵn)
│   ├── app/
│   ├── prompts/
│   └── Dockerfile
│
├── security/                       # ← Day 6
│   ├── promptfooconfig.yaml
│   ├── sample-docs/                # ← Có 1 file poisoned cố ý
│   └── threat-model.md             # Bạn viết
│
├── docs/runbooks/
└── scripts/
    └── verify-day-1.sh ... 7.sh    # Per-day artifact verify
```

### 2.6. Evolution 7 ngày

```
v0  (trước Day 1):  app chạy local, 3 service, ingest đồng bộ
 │
 ├─ Day 1:  refactor async — 5 service, Redis queue
 ├─ Day 2:  containerize đầy đủ, MCP integration
 ├─ Day 3:  Terraform + CI/CD, deploy lên K8s — InsightHub LIVE
 ├─ Day 4:  observable — Prometheus, Grafana, anomaly + AI RCA + MLOps overview
 ├─ Day 5:  ChatOps bot vận hành — query qua Slack
 ├─ Day 6:  secured — red-team sạch, cost-optimized với gateway
 │
v1  (Day 7):  deployment production-grade hoàn chỉnh
```

---

## 3. Pass Criteria & Rubric tổng

### 3.1. Pass Criteria

**Pass = ALL 3 conditions:**

1. **Total score ≥ 70/100** trên rubric 8-dimension.
2. **Attendance ≥ 80%** (12/15 sessions).
3. **Daily artifact ≥ 5/7** nộp đúng hạn.

### 3.2. Rubric tổng 8 Dimensions

| # | Dimension | Weight | Pass threshold |
|---|---|---|---|
| 1 | AI-Augmented Code Quality | 12% | Level 3 (≥61%) |
| 2 | IaC by AI | 13% | Level 3 |
| 3 | CI/CD Pipeline by AI | 13% | Level 3 |
| 4 | Observability & AIOps | 13% | Level 3 |
| 5 | ChatOps Bot | 12% | Level 3 |
| 6 | Security (OWASP) | 12% | Level 3 |
| 7 | FinOps & Cost | 7% | Level 2 (≥41%) |
| 8 | Daily Checkpoint (7 ngày) | 18% | 5/7 daily artifact đạt |

Tổng: **100%**.

### 3.3. Rubric Levels (chung)

Mỗi dimension chấm theo 4 level:

| Level | Score | Mô tả chung |
|---|---|---|
| **Level 1** | 0-40% | Sketch effort, nhiều bug, không có evidence AI-augmented |
| **Level 2** | 41-60% | Partial completion, một số bug, AI doc thiếu |
| **Level 3** | 61-80% | **Pass** — đạt yêu cầu Must-have đầy đủ |
| **Level 4** | 81-100% | Excellence — Must + Should + Nice, senior quality |

Chi tiết per dimension xem trong section Day 1-7.

### 3.4. Cách trainer chấm

Trước Day 7, trainer:

1. **Clone 15 repos** của học viên.
2. Run `scripts/verify-day-N.sh` cho mỗi Day mỗi học viên (automated).
3. **Check artifact URLs** (pipeline runs, dashboard, reports).
4. **Apply rubric** per dimension → assign score.
5. **Return rubric + feedback** qua Slack DM **trước Day 7**.

→ Học viên biết điểm **trước** Day 7. Day 7 là **ăn mừng**, không phải thi.

---

## 4. Submission & Grading Protocol

### 4.1. Daily submission

Mỗi Day 1-6, submit **trước 23:59** ngày Day đó qua Slack channel `#day{N}-submissions`:

```
Day {N} — <Your Name>

✓ Artifact 1: <URL>
✓ Artifact 2: <URL>
✓ Verify command output: <screenshot or paste>
✓ AI prompt log: <URL>
```

### 4.2. Verification scripts

Trainer cung cấp `scripts/verify-day-N.sh` cho mỗi Day. Bạn **tự chạy trước submit**:

```bash
cd insighthub
./scripts/verify-day-1.sh
# → Output PASS/FAIL từng item
```

Tự fix mọi FAIL trước khi submit. Trainer cũng chạy script này để chấm.

### 4.3. Branch & Commit convention

```
Branch: day{N}-<topic>
   day1-refactor
   day2-mcp
   day3-terraform
   day4-observability
   day5-chatops-bot
   day6-security-finops
   day7-showcase

PR Title format:
   [Day N] <Topic short description>
   Vd: [Day 1] Refactor ingestion async + Redis queue

Commit format (Conventional Commits):
   feat(ingestion): tách ingestion-worker + Redis queue
   fix(security): sanitize hidden Unicode in input
   chore(deps): pin terraform-aws-modules version
```

### 4.4. AI Prompt Log convention

File `ai-prompts/day{N}.md` chứa ít nhất 3 prompts đã dùng:

```markdown
# Day 1 AI Prompts

## Prompt 1 — Refactor ingestion async

**Tool**: Claude Code (Sonnet 4.6)
**Time**: 2026-05-19 10:23

**Prompt**:
[Paste prompt with Constraint-first 4-part]

**Why it worked**:
- Constraint-first prompt giúp agent tập trung
- "Trình bày PLAN trước" tạo gate review
- Citing existing pattern in api/services/llm.py giúp agent học style

**What I changed**:
- Reviewed PLAN, rejected step 4 (over-engineering retry logic)
- Approved revised PLAN, agent implemented
- Manual verified test coverage after
```

### 4.5. Trainer Return Format

Trong 24h sau submit, trainer return qua Slack DM:

```
Day {N} Feedback — <Your Name>

Score: <X>/<MAX> (Level <Y>)

✅ Strengths:
- <specific>
- <specific>

⚠️ Improvements needed:
- <specific>
- <specific>

📚 Reference:
- <doc link>

Resubmit deadline (if applicable): <date>
```

### 4.6. Communication channels

| Channel | Purpose |
|---|---|
| `#day{N}-submissions` | Submit artifacts daily |
| `#day{N}-feedback` | Trainer returns rubric (private DM duplicate) |
| `#help-day{N}` | Học viên Q&A peer support |
| `#announcements` | Trainer announces |
| `#day7-showcase` | Day 7 specific |

### 4.7. Late submission policy

- **+0-24h late**: 80% credit (penalty 20%).
- **+24-48h late**: 60% credit.
- **>48h late**: 0 credit cho Day đó.
- **Exception**: medical/family emergency với documentation → no penalty.

### 4.8. Resubmit policy

- Trainer return rubric → bạn có **24h** để resubmit (nếu Day chưa qua quá xa).
- Resubmit chỉ chấm lại **1 lần** — final score.
- Trainer Q&A tại lab có thể adjust score nếu thấy có hiểu lầm.

---

# Phần 2 — Daily Specifications

## 5. Day 1 — AI Coding Agent Refactor

### 5.1. Day Context

**Đã có trước Day 1 (pre-class):**
- ✅ InsightHub v0 clone, `docker-compose up` chạy 3 service (web, api, postgres).
- ✅ Upload sample doc + chat hoạt động (ingest sync, có thể chậm).
- ✅ Claude Code CLI installed + BYOK Anthropic Console.
- ✅ Đã đọc pre-reading Day 1.

**Sẽ làm Day 1:**
1. Khởi tạo `CLAUDE.md` 6-section.
2. Dùng Claude Code đọc hiểu codebase.
3. **REFACTOR**: tách ingestion sync → `ingestion-worker/` + Redis queue (ARQ).
4. Thêm **1 feature mới** AI-augmented.
5. Lưu **AI prompt log** chứng minh workflow.

### 5.2. Mô tả

InsightHub v0 cố ý có điểm yếu: upload file lớn → block API request. Day 1 refactor giúp:
- UX: upload trả 202 ngay, worker xử lý nền.
- Scale: worker scale độc lập.
- Foundation: Day 4 mới observe được queue depth.

**Business value**: từ "user thử lại 3 lần vì timeout" → "upload ngay, status update real-time".

### 5.3. Mục tiêu

**Functional:**
1. `docker-compose up` chạy 5 service.
2. Upload → API trả 202 trong < 1s (không block).
3. Worker dequeue → chunk + embed + store → status "ready".
4. Chat API vẫn hoạt động đúng.
5. 1 feature mới (vd: hiển thị nguồn trích dẫn).

**Non-functional:**
1. Code style: `ruff format` + type hints + mypy strict.
2. Tests cũ pass (`pytest -xvs`).
3. Không break API contract.
4. Không đổi schema DB.
5. Secret qua env var, không hardcode.

**Learning:**
1. Setup Claude Code BYOK + permission 3-tier.
2. Viết CLAUDE.md 6-section ≤ 200 dòng.
3. Áp dụng **Constraint-first prompt** 4-part.
4. Hiểu agentic loop (perceive → reason → act → observe).
5. Review code AI sinh như review junior.

### 5.4. Yêu cầu chi tiết

**Must-have (bắt buộc PASS):**

| # | Requirement | Verify |
|---|---|---|
| MH1 | `CLAUDE.md` đầy đủ 6 section (Architecture, Conventions, Commands, Constraints, Domain, References) | Read file |
| MH2 | `CLAUDE.md` ≤ 200 dòng | `wc -l CLAUDE.md` |
| MH3 | `ingestion-worker/` directory với Dockerfile, worker.py, requirements.txt | `ls ingestion-worker/` |
| MH4 | `docker-compose.yml` có 5 service | `docker-compose config --services \| wc -l` = 5 |
| MH5 | `docker-compose up` không lỗi | All Running |
| MH6 | Upload → API trả 202 trong < 1s | `curl -X POST /upload` check time |
| MH7 | Worker process → status "ready" trong < 30s | Poll `/documents/<id>/status` |
| MH8 | Chat API vẫn trả answer đúng | `curl -X POST /chat` non-empty |
| MH9 | `pytest -xvs` pass | CI logs |
| MH10 | 1 PR với title `[Day 1] Refactor ingestion async + Redis queue` | GitHub URL |
| MH11 | `ai-prompts/day1.md` ≥ 3 prompts có giải thích | Read file |

**Should-have (Level 3+):**
- 1 feature mới: hiển thị nguồn trích dẫn trong chat response
- Type hints + mypy strict pass
- Worker có retry logic (3 lần exponential backoff)
- Health check endpoint cho worker
- Worker log structured JSON
- CLAUDE.md có forbidden patterns cụ thể

**Nice-to-have (Level 4):**
- Prometheus metrics endpoint trên worker (chuẩn bị Day 4)
- Graceful shutdown (SIGTERM handler)
- Pre-commit hook tự chạy ruff + mypy

### 5.5. Acceptance Criteria

```
[ ] git clone <my-repo> && cd insighthub
[ ] cat CLAUDE.md  → 6 sections, ≤ 200 dòng
[ ] docker-compose config --services | wc -l  → 5
[ ] docker-compose up -d  → all 5 containers Running
[ ] curl -X POST localhost:8000/upload -F "file=@sample.pdf"  → 202 in <1s
[ ] curl localhost:8000/documents/<id>/status  → "ready" within 30s
[ ] curl -X POST localhost:8000/chat -d '{...}'  → 200 + answer
[ ] pytest api/tests/ -xvs  → all pass
[ ] cat ai-prompts/day1.md  → ≥ 3 prompts documented
[ ] PR exists với title format đúng
```

### 5.6. Rubric Day 1 — AI-Augmented Code Quality (12%)

| Level | Score | Criteria |
|---|---|---|
| **L1** | 0-3 pts | Code chạy nhưng không có AI prompt log. Không refactor (vẫn sync). CLAUDE.md thiếu hoặc không có. |
| **L2** | 4-7 pts | Refactor 1 phần bằng AI, không document prompt. CLAUDE.md có nhưng thiếu section. Vài bugs. |
| **L3** | 8-9 pts | Refactor + feature mới rõ. AI prompt log đầy đủ ≥3 prompts. Code clean (ruff pass). CLAUDE.md 6-section. |
| **L4** | 10-12 pts | Refactor chất lượng senior. CLAUDE.md ≤200 dòng có forbidden patterns. ingestion-worker retry logic + structured log. |

**Pass threshold**: L3 (≥ 8 pts).

### 5.7. Common Pitfalls (tự tham khảo khi gặp lỗi)

| Pitfall | Triệu chứng | Cách fix |
|---|---|---|
| **claude không chạy** | `command not found` | Reinstall: `npm install -g @anthropic-ai/claude-code`; check Node 20+ |
| **Login fail** | API key invalid | Regenerate key trên Anthropic Console; `claude login` lại |
| **CLAUDE.md quá dài** | Agent ignore phần giữa | Quy tắc ≤ 200 dòng; dùng table thay text |
| **Agent loop forever** | Cùng cách lặp 10 lần | Stop. Rephrase prompt. Set `--max-turns 20` |
| **Worker không nhận job** | Job trong queue Redis nhưng worker không pop | Cả api và worker phải trỏ cùng `REDIS_URL` |
| **"event loop already running"** | Worker crash | `process_document` sync gọi trong async — bọc `run_in_executor` |
| **Upload vẫn block** | 202 không trả ngay | Check `api/routers/documents.py` còn gọi `ingest_document_sync`? Đổi sang `enqueue_job` |
| **Docker build fail worker** | `Module not found: arq` | Thêm `arq`, `psycopg2-binary`, `pgvector`, `voyageai` vào `ingestion-worker/requirements.txt` |
| **/cost vọt** | $5+ trong 30 phút | `/clear` giữa task; CLAUDE.md cô đọng; route Haiku cho task đơn giản |

### 5.8. Submission Format

Submit Slack `#day1-submissions` trước **23:59 cùng ngày Day 1**:

```
Day 1 — <Your Name>

✓ Repo: https://github.com/<username>/insighthub
✓ CLAUDE.md: <URL>
✓ PR refactor: <URL>
✓ Prompt log: <URL>
✓ Verify output:
   docker-compose ps  → 5 service Running ✓
   curl /upload time  → < 1s ✓
   pytest output     → pass ✓
```

### 5.9. Self-Check Questions

1. CLAUDE.md của tôi có 6 section nào? Có forbidden patterns cụ thể không?
2. Tôi dùng pattern Constraint-first 4-part không? Constraints nào tôi nêu?
3. Tôi review PLAN trước khi approve không? Có bước nào tôi hỏi lại agent?
4. ingestion-worker chạy độc lập — nếu tôi stop nó, API có còn hoạt động không?
5. Upload doc lớn (10MB+) bây giờ trả 202 trong bao nhiêu giây?
6. AI prompt log của tôi có gì? Liệt kê 3 prompts tốt nhất + giải thích vì sao chúng tốt.
7. Nếu trainer hỏi "Vì sao chọn ARQ thay vì Celery?" — tôi trả lời thế nào?

---

## 6. Day 2 — MCP Protocol Integration

### 6.1. Day Context

**Đã có trước Day 2:**
- ✅ Day 1: InsightHub v1 với 5 service async.
- ✅ CLAUDE.md đầy đủ.
- ✅ Pre-class: kubeconfig context cho lab cluster, IAM user `mcp-readonly` (ReadOnlyAccess).

**Sẽ làm Day 2:**
1. Cấu hình `.mcp.json` với **4+ MCP servers** (Filesystem, Docker, K8s, Prometheus).
2. Verify Connected qua `claude mcp list`.
3. Setup ServiceAccount K8s read-only riêng.
4. Setup IAM mcp-readonly profile AWS.
5. Debug session thực tế qua MCP (vd crashed container).

### 6.2. Mô tả

Day 1 dùng Claude Code đọc file local OK. Nhưng debug pod crash trong cluster? Claude không tự kết nối. Bạn cần **MCP** — "USB-C cho AI agent" — cho Claude touch các tool/data ngoài codebase.

**Business value**: Debug pod crash từ ~25 phút → ~45 giây.

### 6.3. Mục tiêu

**Functional:**
1. `.mcp.json` với 4+ servers stdio transport.
2. `claude mcp list` → tất cả ✓ Connected.
3. Inspector test mỗi MCP → invoke 1 tool thành công.
4. Debug session log: crashed container → AI dùng Docker MCP → RCA.

**Non-functional:**
1. Credentials **stay local** — không commit secret vào Git.
2. K8s MCP dùng ServiceAccount **read-only** riêng.
3. AWS MCP dùng IAM `mcp-readonly` profile.
4. Filesystem MCP allow-list **chỉ** project directory.
5. MCP server version pinned trong `.mcp.json`.

**Learning:**
1. Hiểu architecture 3-vai-trò (Host / Client / Server).
2. Hiểu 3 primitives (Tools / Resources / Prompts).
3. Hiểu transport stdio vs Streamable HTTP — khi nào dùng cái nào.
4. Setup ServiceAccount K8s với ClusterRole read-only.
5. Debug MCP server không kết nối qua Inspector.

### 6.4. Yêu cầu chi tiết

**Must-have:**

| # | Requirement | Verify |
|---|---|---|
| MH1 | `.mcp.json` valid JSON | `cat .mcp.json \| jq .` |
| MH2 | 4+ mcpServers configured | `jq '.mcpServers \| keys \| length'` ≥ 4 |
| MH3 | Tất cả servers Connected | `claude mcp list` no ❌ |
| MH4 | Server versions pinned (không `@latest`) | Read .mcp.json |
| MH5 | K8s MCP: ServiceAccount `mcp-readonly` tồn tại | `kubectl get sa mcp-readonly -n insighthub` |
| MH6 | K8s ClusterRole: read-only verbs only | `kubectl get clusterrole mcp-readonly -o yaml` |
| MH7 | Filesystem MCP: allow-list **chỉ** project dir | Inspect `.mcp.json` |
| MH8 | Inspector test pass cho mỗi server | Screenshot |
| MH9 | Debug session log (markdown) ≥ 1 case study | `debug-session-day2.md` |
| MH10 | Mini-quiz 10 câu ≥ 7/10 | Quiz form |

**Should-have:**
- 5+ MCP servers (thêm AWS MCP)
- Pin namespace + context trong env
- `--read-only` flag cho Kubernetes MCP
- `.env.example` template

**Nice-to-have:**
- 6 MCP servers (thêm Terraform MCP chuẩn bị Day 3)
- Custom MCP server cho tool nội bộ (FastMCP) — bonus
- Threat model document cho mỗi MCP server

### 6.5. Acceptance Criteria

```
[ ] cat .mcp.json | jq .  → valid JSON
[ ] jq '.mcpServers | keys | length' .mcp.json  → ≥ 4
[ ] claude mcp list  → all ✓ Connected
[ ] All versions pinned (no @latest)
[ ] kubectl get sa mcp-readonly -n insighthub  → exists
[ ] kubectl auth can-i delete pods --as=system:serviceaccount:insighthub:mcp-readonly  → "no" ✅
[ ] kubectl auth can-i get pods --as=system:serviceaccount:insighthub:mcp-readonly  → "yes" ✅
[ ] aws --profile mcp-readonly sts get-caller-identity  → mcp-readonly user
[ ] Inspector: invoke get_pods → returns pod list
[ ] debug-session-day2.md exists with ≥ 1 case study
```

### 6.6. Rubric Day 2 — Foundation cho Dim 1 + 4 + 5

Day 2 không có dimension riêng — đóng góp vào:
- **Dim 1** AI-Augmented Code Quality (MCP integration documented trong CLAUDE.md)
- **Dim 4** Observability (Day 4 dùng Prometheus MCP)
- **Dim 5** ChatOps Bot (Day 5 dùng MCP backend)

**Sub-criteria Day 2:**

| Sub-criteria | Pass condition |
|---|---|
| `.mcp.json` quality | 4+ servers, pinned versions, allow-list paths |
| Security posture | RBAC read-only, IAM ReadOnlyAccess, stdio transport |
| Documentation | `debug-session-day2.md` rõ ràng |
| Quiz | ≥ 7/10 |

### 6.7. Common Pitfalls

| Pitfall | Triệu chứng | Fix |
|---|---|---|
| **kubectl connect fail** | `unable to connect to cluster` | Check `KUBECONFIG` env; `kubectl get pods` từ shell trước |
| **K8s MCP Forbidden** | `cannot list pods` | RBAC sai — recheck ClusterRoleBinding namespace |
| **AWS MCP AccessDenied** | Tool fail | Profile `mcp-readonly` chưa set; SSO expired (`aws sso login`) |
| **Filesystem MCP đọc nhầm file** | Agent đọc `~/.ssh/` | Allow-list quá rộng — pin về project dir |
| **NPM package not found** | `kubernetes-mcp-server: not found` | Version syntax sai (vd `@1` thay vì `@1.0`) |
| **Inspector port conflict** | Port 6274 in use | `--port 6275` flag |
| **JSON syntax error** | `.mcp.json` parse fail | `jq . .mcp.json` validate; common: trailing comma |

### 6.8. Submission Format

```
Day 2 — <Your Name>

✓ .mcp.json: <URL>
✓ Servers connected: <screenshot claude mcp list>
✓ ServiceAccount yaml: <URL>
✓ Debug session log: <URL>
✓ Quiz score: 9/10
```

### 6.9. Self-Check Questions

1. Tôi list 4 servers trong `.mcp.json` — server nào? Tại sao chọn 4 này?
2. Server nào dùng `--read-only` flag? Tại sao?
3. ServiceAccount `mcp-readonly` có verb gì? Tại sao KHÔNG có `delete`?
4. Filesystem MCP allow-list path nào? Tại sao không `$HOME`?
5. Khi MCP server không kết nối, tôi debug thế nào? (Hint: Inspector)
6. `stdio` vs `Streamable HTTP` — Day 2 dùng cái nào? Tại sao?
7. 3 vai trò Host / Client / Server — ai chịu trách nhiệm bảo mật?

---

## 7. Day 3 — AI-Powered IaC & Pipeline

### 7.1. Day Context

**Đã có trước Day 3:**
- ✅ Day 1-2: InsightHub v1 + `.mcp.json` 4+ servers.
- ✅ AWS account + Terraform v1.9+, tflint, checkov installed.
- ✅ Lab cluster K8s sẵn sàng.

**Sẽ làm Day 3:**
1. AI sinh **Terraform module** cho InsightHub: EKS namespace + RDS pgvector + ElastiCache Redis.
2. Áp dụng **3-Layer Defense**: AI generate → human review → policy gate (tflint + checkov + Conftest).
3. AI sinh **GitHub Actions** pipeline multi-stage.
4. Deploy InsightHub lên K8s — **InsightHub LIVE**.

### 7.2. Mô tả

InsightHub v1 chạy local. Cần deploy lên cloud cho team test. Đây là task chuyển paradigm: "Infrastructure as Code" → "Infrastructure as Intention" — viết spec, AI sinh code, policy gate verify.

**Business value**: Click console 50 lần → 1 spec file + AI sinh + policy gate → tái tạo môi trường staging/prod từ cùng codebase.

### 7.3. Mục tiêu

**Functional:**
1. Terraform module deploy được trên AWS.
2. EKS namespace `insighthub-<env>` tạo thành công.
3. RDS PostgreSQL 16 + pgvector, encrypted, không public.
4. ElastiCache Redis 7, không public, trong VPC.
5. IRSA cho pod IAM (không IAM user).
6. GitHub Actions: fmt → lint → scan → policy → plan → cost → apply (manual approval).
7. InsightHub deploy K8s, accessible HTTPS.
8. Smoke test pass: upload → ingest → chat.

**Non-functional:**
1. `tflint --recursive` no warnings.
2. `checkov -d infra/` no HIGH.
3. `conftest test ... tfplan.json` pass.
4. Tags đầy đủ: project, environment, owner, cost_center, managed_by.
5. Pipeline OIDC AWS (no long-lived keys).
6. Secret qua AWS Secrets Manager.
7. Infracost ≤ $50/month for dev env.

**Learning:**
1. Áp dụng Spec-driven development cho IaC.
2. Áp dụng 3-Layer Defense pattern.
3. Viết Rego policy cho org-specific rules.
4. Setup OIDC AWS trust với GitHub Actions.
5. Sinh multi-stage CI/CD bằng AI + verify.
6. Khi nào dùng managed service (RDS) vs StatefulSet trong cluster.

### 7.4. Yêu cầu chi tiết

**Must-have:**

| # | Requirement | Verify |
|---|---|---|
| MH1 | `infra/` complete: main.tf, variables.tf, outputs.tf, providers.tf | `ls infra/` |
| MH2 | Terraform backend S3 + DynamoDB lock | `cat infra/backend.tf` |
| MH3 | EKS namespace resource | `terraform state list \| grep namespace` |
| MH4 | RDS PostgreSQL 16, encrypted, not public | Plan output |
| MH5 | ElastiCache Redis 7, private subnet | Plan output |
| MH6 | IRSA: ServiceAccount + IAM Role binding | `kubectl describe sa insighthub` |
| MH7 | `.github/workflows/iac.yml` exists | `cat file` |
| MH8 | Pipeline jobs: fmt, lint, security-scan, policy-check, plan, cost-estimate, apply | `gh workflow view` |
| MH9 | Pipeline green on PR | `gh run list` shows ✓ |
| MH10 | InsightHub Helm deploy | `kubectl get pods` 5 Running |
| MH11 | Smoke test: upload + chat | curl tests |
| MH12 | `tflint --recursive` no warnings | CI logs |
| MH13 | `checkov` no HIGH | CI logs |
| MH14 | All resources tagged | AWS describe-tags |

**Should-have:**
- Conftest Rego policies (tags, encryption, cost guardrails)
- Infracost comment on PR
- Multi-environment workspace (dev / staging)
- AI explain plan output in PR comment
- Manual approval gate cho production

**Nice-to-have:**
- Modular reusable Terraform submodules
- Custom Rego policy cho org-specific
- Backup strategy: RDS snapshots 7 days
- Drift detection scheduled (nightly cron)

### 7.5. Acceptance Criteria

```
[ ] terraform fmt -check -recursive  → no diff
[ ] terraform init -backend=true  → success
[ ] terraform validate  → success
[ ] tflint --recursive  → 0 errors, 0 warnings
[ ] checkov -d infra/  → no HIGH
[ ] terraform plan -out=tfplan  → deterministic
[ ] conftest test --policy policy/terraform tfplan.json  → pass
[ ] infracost breakdown --path infra/  → < $50/mo for dev
[ ] gh run list --workflow=iac.yml  → ✓ success
[ ] kubectl get ns insighthub-dev  → exists
[ ] kubectl get pods -n insighthub-dev  → 5/5 Running
[ ] curl https://insighthub-dev.example.com/health  → 200 OK
[ ] curl -X POST .../upload -F file=@test.pdf  → 202
[ ] GET /documents/<id>/status  → "ready" within 30s
[ ] curl -X POST .../chat  → 200 + answer
```

### 7.6. Rubric Day 3 — IaC (13%) + CI/CD (13%) = 26%

**Dim 2 — IaC by AI (13%):**

| Level | Score | Criteria |
|---|---|---|
| L1 | 0-5 | Terraform copy-paste, không pass checkov. Hardcode credentials. |
| L2 | 6-7 | Terraform AI-gen nhưng còn HIGH severity. Missing tags. |
| L3 | 8-10 | Module Terraform clean, pass checkov no-HIGH. IRSA setup. |
| L4 | 11-13 | Multi-module, IRSA/least-privilege, pass checkov + tflint + Conftest, README+diagrams. |

**Dim 3 — CI/CD Pipeline by AI (13%):**

| Level | Score | Criteria |
|---|---|---|
| L1 | 0-5 | Pipeline manual hoặc không green. Hardcode secret. |
| L2 | 6-7 | Pipeline AI-gen nhưng skip security scan. Long-lived AWS keys. |
| L3 | 8-10 | Pipeline đầy đủ: build → test → scan → deploy. Green. OIDC AWS. |
| L4 | 11-13 | Multi-stage + matrix + caching + secret management + approval gate. Infracost comment. AI explain plan. |

**Pass**: Cả 2 Dim L3 (≥ 8 pts each).

### 7.7. Common Pitfalls

| Pitfall | Triệu chứng | Fix |
|---|---|---|
| **OIDC trust sub: wrong** | `Could not assume role` | Check `sub:` claim match `repo:OWNER/REPO:*` |
| **Backend S3 not exists** | `terraform init` fail | Create S3 bucket + DynamoDB table first |
| **State locked** | `Error acquiring state lock` | Check DynamoDB lock; `terraform force-unlock` if safe |
| **Provider version conflict** | `error from provider` | Pin `required_providers` |
| **checkov fail too many** | 20+ HIGH | Group by type, fix as group |
| **Plan shows surprise destroys** | `Plan: X to destroy` unexpected | DO NOT apply. Investigate drift |
| **RDS pgvector extension missing** | Extension not loaded | Add custom DB parameter group với `shared_preload_libraries = vector` |
| **IRSA not working** | Pod gets AccessDenied | Check OIDC provider exists; service account annotation correct |

### 7.8. Submission Format

```
Day 3 — <Your Name>

✓ Terraform module: <URL>
✓ Pipeline run (green): <URL>
✓ checkov scan report: <URL>
✓ Infracost report: <PR comment URL>
✓ InsightHub live URL: https://insighthub-<u>.example.com
✓ Smoke test screenshots:
   - GET /health → 200
   - POST /upload → 202
   - POST /chat → answer
```

### 7.9. Self-Check Questions

1. SPEC.md tôi viết có những section nào? Acceptance criteria có đo được không?
2. 3-Layer Defense gồm những lớp nào? Layer nào bắt loại lỗi gì?
3. tflint vs checkov vs Conftest — mỗi cái cho việc gì?
4. OIDC AWS trust hoạt động thế nào? Vì sao tốt hơn long-lived keys?
5. Cost estimate của tôi là bao nhiêu?
6. Resource nào của tôi có tag không đầy đủ?
7. Tại sao dùng RDS managed thay vì Postgres trong cluster StatefulSet?

---

## 8. Day 4 — AIOps + MLOps Overview

### 8.1. Day Context

**Đã có trước Day 4:**
- ✅ Day 1-3: InsightHub LIVE trên EKS, 5 service Running.
- ✅ `api/app/core/metrics.py` có sẵn Prometheus metrics.
- ✅ Pre-class: Grafana Cloud account, kube-prometheus-stack installed.

**Sẽ làm Day 4:**
1. ServiceMonitor → Prometheus scrape InsightHub.
2. Grafana dashboard RED method.
3. Anomaly detection rules (promql-anomaly-detection).
4. Inject 3 incidents → AI RCA workflow (Claude + Prometheus MCP + K8s MCP).
5. 🆕 Hiểu **MLOps Architecture Overview** (25' lecture, không hands-on).

### 8.2. Mô tả

InsightHub LIVE (Day 3). User báo "đôi khi chậm" → bạn không biết khi nào, ở đâu. Cần observability.

**Day 4 = "I can see what's broken before users complain."**

Bonus: nếu mai team có model riêng, bạn cần biết MLOps architecture overview để phối hợp với ML team — 25 phút overview, không hands-on.

**Business value**: User complain → check dashboard → guess root cause (~25 phút MTTR) → trở thành "anomaly fire trước user complain → AI RCA report sẵn → fix in ~5 phút MTTR".

### 8.3. Mục tiêu

**Functional:**
1. Prometheus scrape 5 service (ServiceMonitor).
2. Grafana dashboard ≥ 9 panels: rate / errors / duration / queue depth / token usage / latency_p95 / cost / pod resources / deploy annotations.
3. Anomaly band rules cho 3 metric: LLM latency, queue depth, error rate.
4. Alertmanager → Slack `#alerts` khi anomaly fire.
5. Inject 3 incident → AI RCA report JSON structured.

**Non-functional:**
1. Baseline data ≥ 1h trước alert (lab); ≥ 7 ngày production.
2. Resource limits Prometheus pod.
3. Recording rules cho expensive query.
4. Retention 15 ngày.
5. AI RCA prompt force "evidence-first".

**Learning:**
1. Áp dụng RED + USE methods.
2. Khi nào dùng statistical anomaly vs ML-based.
3. "Correlation > Detection" pattern.
4. Tránh hallucination trong LLM-RCA.
5. 🆕 Hiểu ML lifecycle map.
6. 🆕 Hiểu 4 khái niệm MLOps core: Registry, Approval Gate, Drift, Rollback.
7. 🆕 Ownership boundary: DevOps vs ML Engineer.

### 8.4. Yêu cầu chi tiết

**Must-have:**

| # | Requirement | Verify |
|---|---|---|
| MH1 | ServiceMonitor applied | `kubectl get servicemonitor` |
| MH2 | Prometheus scraping all 5 services | `prom:9090/targets` UP |
| MH3 | Grafana dashboard ≥ 9 panels | Screenshot |
| MH4 | Recording rules cho anomaly bands | `kubectl get prometheusrule` |
| MH5 | Alert rules cho 3 anomaly | `promtool check rules` |
| MH6 | Alertmanager → Slack | Test alert in channel |
| MH7 | Incident #1 (LLM latency spike) → anomaly + AI RCA | `incident-1.json` |
| MH8 | Incident #2 (queue backlog) → anomaly + AI RCA | `incident-2.json` |
| MH9 | Incident #3 (error burst) → anomaly + AI RCA | `incident-3.json` |
| MH10 | RCA reports cite metric + timestamp | Read JSON |
| MH11 | Quiz 5 câu pass ≥ 4/5 | Quiz form |
| MH12 | MLOps overview notes (4 block) | `mlops-overview-notes.md` |

**Should-have:**
- Grafana Sift integration (Pro tier)
- Custom alert routing per severity
- Adaptive Telemetry: tail sampling + log filtering
- SLO + burn rate alerts
- Runbook annotation per alert

**Nice-to-have:**
- Knowledge graph for observability
- Auto-draft postmortem
- Chaos engineering integration
- Cost dashboard cho observability stack

### 8.5. Acceptance Criteria

```
[ ] kubectl get servicemonitor -n insighthub  → exists
[ ] curl prom:9090/api/v1/targets  → 5 InsightHub targets UP
[ ] Grafana dashboard URL  → 9+ panels, no "No data"
[ ] kubectl get prometheusrule -n monitoring -o yaml  → rules
[ ] promtool check rules anomaly-rules.yaml  → SUCCESS
[ ] Test alert → reach Slack #alerts
[ ] ./scripts/chaos/inject-llm-latency.sh  → alert fires in 5min
[ ] cat rca-reports/incident-1.json  → JSON with evidence + timestamp
[ ] cat rca-reports/incident-2.json  → same
[ ] cat rca-reports/incident-3.json  → same
[ ] cat mlops-overview-notes.md  → 4 block summary
[ ] Quiz: 5/5
```

### 8.6. Rubric Day 4 — Observability & AIOps (13%)

| Level | Score | Criteria |
|---|---|---|
| L1 | 0-5 | Prometheus scrape có nhưng không có anomaly. Dashboard sơ sài. |
| L2 | 6-7 | Anomaly rules có nhưng không fire thật, không có RCA. |
| L3 | 8-10 | Anomaly alert configured + 1 AI RCA report. Dashboard RED đầy đủ. MLOps overview understood. |
| L4 | 11-13 | Multiple SLI/SLO + 3 AI RCA + Grafana Sift integration + runbook per alert. |

**Pass**: L3 (≥ 8 pts).

### 8.7. Common Pitfalls

| Pitfall | Triệu chứng | Fix |
|---|---|---|
| **ServiceMonitor không scrape** | Targets empty | Check label `release: kube-prom-stack` match |
| **`up == 0`** | Target DOWN | Service `port` name match ServiceMonitor field |
| **Memory vọt Prometheus** | OOMKilled | Reduce retention, check label cardinality (no user_id!) |
| **Alert flapping** | Fires/clears repeatedly | `for: 2m` longer than scrape interval |
| **All metrics flagged anomaly** | Baseline too short | Wait 24h+; 5min min lab |
| **Recording rule fail** | Metric doesn't compute | `promtool check rules`; verify expr |
| **Slack webhook silent** | No alert in channel | Verify Alertmanager config |
| **AI RCA hallucinate** | Cites non-existent metric | Force "evidence-first" + "cite metric+timestamp" in prompt |

### 8.8. Submission Format

```
Day 4 — <Your Name>

✓ ServiceMonitor: <URL>
✓ Grafana dashboard URL: <URL>
✓ Anomaly rules: <URL>
✓ RCA reports:
  - incident-1.json (LLM latency)
  - incident-2.json (queue backlog)
  - incident-3.json (error burst)
✓ MLOps overview notes: <URL>
✓ Quiz: 5/5
```

### 8.9. Self-Check Questions

**AIOps:**
1. ServiceMonitor scrape mấy service? 30s interval đủ chưa?
2. Anomaly band 3*stddev — false positive rate trong 1h?
3. 3 incident — cái nào dễ phát hiện nhất? Vì sao?
4. RCA report có cite metric + timestamp không? Confidence > 0.7?
5. Correlation > Detection — apply ở incident nào?

**🆕 MLOps:**
6. App vs Model artifact khác nhau ở 4 chiều nào?
7. Drift data vs Drift concept — khác nhau thế nào?
8. Nếu team có model riêng và drift fire, DevOps làm gì?
9. Khi nào DevOps tự retrain model? (Hint: KHÔNG bao giờ)
10. Ownership boundary table — stage nào DevOps own PRIMARY?

---

## 9. Day 5 — ChatOps Bot & Incident Response

### 9.1. Day Context

**Đã có trước Day 5:**
- ✅ Day 1-4: InsightHub observed với anomaly + RCA workflow.
- ✅ MCP backend (K8s + Prometheus) setup Day 2.
- ✅ Pre-class: Slack workspace + App created + ngrok ready.

**Sẽ làm Day 5:**
1. Hoàn thiện `chatops-bot/` skeleton: FastAPI + Slack SDK + MCP client + audit log.
2. Implement 3 intent:
   - "InsightHub có healthy không?"
   - "Hôm nay ingest bao nhiêu doc?"
   - "Pod nào đang lỗi?"
3. Verify Slack signature + 3-tier permission system.
4. Deploy bot local qua ngrok hoặc K8s production.

### 9.2. Mô tả

InsightHub có observability (Day 4). Nhưng on-call 3h sáng KHÔNG muốn mở 5 tab Grafana. Họ muốn **hỏi 1 câu trong Slack** → AI bot trả ngay.

**Day 5 = "Detection → Triage → Action through chat" — full loop incident response.**

**Business value**: On-call coordination tax 15 phút → 5 giây trả lời với context + recommendation.

### 9.3. Mục tiêu

**Functional:**
1. Bot reachable từ Slack (ngrok hoặc public Ingress).
2. Bot verify Slack signature mọi request.
3. Bot trả lời 3 intent với MCP backend.
4. Permission 3-tier: read auto, write ask-confirm, destructive token.
5. Audit log mọi tool call (JSON structured).

**Non-functional:**
1. Bot respond < 3s (Slack timeout).
2. Background task cho LLM call dài.
3. ServiceAccount K8s read-only riêng.
4. Slack bot token in K8s Secret, không hardcode.
5. Signature reject request > 5 phút (replay defense).

**Learning:**
1. Slack Bot architecture: events → signature → handler → reply.
2. Permission 3-tier cho bot action.
3. Audit log structured cho compliance.
4. Pattern "AI recommends, humans approve, systems execute".
5. (Optional) Deploy bot K8s production-ready với IRSA + Ingress + TLS.

### 9.4. Yêu cầu chi tiết

**Must-have:**

| # | Requirement | Verify |
|---|---|---|
| MH1 | `chatops-bot/` structure complete | `tree chatops-bot/` |
| MH2 | FastAPI app `/slack/events` endpoint | `uvicorn` runs |
| MH3 | Signature verification implemented | Test reject invalid |
| MH4 | Bot deploy local + ngrok URL working | Public URL |
| MH5 | Slack App configured (scopes + event URL) | Mention bot test |
| MH6 | 3 intents implemented | Test in Slack |
| MH7 | MCP backend (K8s + Prometheus reuse Day 2) | Audit log shows MCP calls |
| MH8 | Audit log JSON structured | Read log file |
| MH9 | Permission tier enforced | Test scale action |
| MH10 | Tests pass (`pytest chatops-bot/tests/`) | CI logs |
| MH11 | Demo screencast 3' (Loom) | URL submitted |

**Should-have:**
- Confirmation token system (60s timeout)
- Multi-step LLM tool calling loop
- Service catalog YAML
- Slack interactive components
- Replay attack defense

**Nice-to-have:**
- K8s production deployment
- HPA autoscale
- Loki log aggregation
- A2UI experiment
- `/catchup` intent

### 9.5. Acceptance Criteria

```
[ ] tree chatops-bot/  → app/, prompts/, tests/, Dockerfile
[ ] cd chatops-bot && uvicorn app.main:app  → runs
[ ] curl -X POST /slack/events with invalid sig  → 401 ✓
[ ] Slack: @bot "api healthy?"  → bot replies
[ ] Slack: @bot "ingest count today?"  → bot returns count
[ ] Slack: @bot "which pods failing?"  → bot lists pods
[ ] cat chatops-audit.log  → JSON entries
[ ] Slack: @bot "scale api to 5"  → bot asks confirm với token
[ ] pytest chatops-bot/tests/  → all pass
[ ] Loom screencast URL submitted
```

### 9.6. Rubric Day 5 — ChatOps Bot (12%)

| Level | Score | Criteria |
|---|---|---|
| L1 | 0-4 | Bot không deploy được, hoặc signature không verify |
| L2 | 5-7 | Bot trả lời text đơn giản, không có MCP backend |
| L3 | 8-9 | Bot có MCP backend, trả lời 3 câu infra với enriched context. Audit trail có. |
| L4 | 10-12 | Bot multi-tool, approval gate, audit+monitoring, K8s production deploy |

**Pass**: L3 (≥ 8 pts).

### 9.7. Common Pitfalls

| Pitfall | Triệu chứng | Fix |
|---|---|---|
| **Slack signature mismatch** | All 401 | Body parsing — đọc RAW body trước parse JSON |
| **Bot timeout 3s** | Slack "request URL failed" | BackgroundTasks; return 200 immediately |
| **Bot không nhận event** | Mention không trigger | Subscribe Events ON; check Request URL Verified |
| **Bot reply to itself** | Infinite loop | Filter `event.user == bot_user_id` |
| **MCP tool Forbidden** | Permission error | RBAC ServiceAccount issue (Day 2) |
| **Audit log mất** | File not created | Check log path + write permission |
| **Confirmation token expired ngay** | Always "Token expired" | Time zone consistent UTC |

### 9.8. Submission Format

```
Day 5 — <Your Name>

✓ chatops-bot/ source: <URL>
✓ Loom screencast (3 min): https://loom.com/<id>
✓ Audit log sample: <URL>
✓ Bot live URL (if K8s deploy): <URL>
✓ Slack interaction screenshot: <URL>
```

### 9.9. Self-Check Questions

1. Signature verification có reject request > 5 phút không?
2. 3 intents — intent nào dùng nhiều tool call nhất?
3. Audit log có field nào? Có timestamp + user + tool + result không?
4. Permission tier — write asks confirm thế nào? Token expires sau bao lâu?
5. Bot respond < 3s — tôi dùng BackgroundTasks pattern không?
6. Service catalog có những service nào? Owner đầy đủ chưa?
7. Vì sao bot cần audit log?

---

## 10. Day 6 — Security, Governance & FinOps

### 10.1. Day Context

**Đã có trước Day 6:**
- ✅ Day 1-5: InsightHub deployed, observed, ChatOps bot live.
- ✅ Pre-class: Promptfoo installed, OWASP LLM Top 10 v2025 đọc qua.

**Sẽ làm Day 6:**
1. Red team InsightHub bằng **Promptfoo** — quét OWASP LLM Top 10.
2. Discover & fix indirect prompt injection (poisoned-doc trong sample-docs).
3. Add **Guardrails** (Bedrock hoặc NeMo hoặc Llama Guard 3).
4. Setup **LiteLLM Gateway** với virtual keys + budget caps.
5. Build cost dashboard + AWS Budgets alert.
6. Document **threat model**.

### 10.2. Mô tả

5 ngày qua bạn đã trao AI ngày càng nhiều quyền (Day 1 code, Day 2 cluster MCP, Day 3 cloud IaC, Day 4 metrics, Day 5 ChatOps execute). **Day 6 = "trả nợ"** — đảm bảo mọi quyền đó được kiểm soát.

Và LLM API đắt (10-100x chatbot thường) — không control → bill shock.

> ⚠️ **Day 6 phân biệt "làm được" và "làm có trách nhiệm".**

**Business value**: Trước Day 6 = vulnerable to indirect injection + bill shock. Sau Day 6 = Promptfoo CI/CD scan + Guardrails block + Gateway hard budget cap.

### 10.3. Mục tiêu

**Functional:**
1. Promptfoo config với OWASP preset + custom plugins.
2. Initial scan find vulnerabilities (CRITICAL/HIGH).
3. Fix qua: input sanitization, prompt hardening, guardrails.
4. Final scan: no HIGH/CRITICAL.
5. Guardrails enabled wrap LLM call.
6. LiteLLM gateway routing InsightHub + ChatOps bot + Claude Code.
7. 3 virtual keys với budget cap.
8. Cost dashboard Grafana.
9. AWS Budgets alert configured.

**Non-functional:**
1. All HIGH/CRITICAL findings documented.
2. Hard budget cap at gateway (real-time).
3. Audit log every LLM call.
4. Threat model 6+ threats với mitigation.
5. Cost attribution per request (tagged).

**Learning:**
1. OWASP LLM Top 10 v2025 (10 entries).
2. OWASP Agentic Top 10 (ASI01-04 chính).
3. Defense in Depth pattern (6 layers).
4. LiteLLM gateway + budget enforcement.
5. Token economics + 4 trụ cột FinOps.
6. Anthropic prompt caching pattern (90% discount).

### 10.4. Yêu cầu chi tiết

**Must-have:**

| # | Requirement | Verify |
|---|---|---|
| MH1 | `security/promptfooconfig.yaml` configured | File exists |
| MH2 | Plugins: prompt-injection, indirect-prompt-injection, rag-poisoning, pii, excessive-agency | YAML content |
| MH3 | Initial scan report | `red-team-report.html` |
| MH4 | Fix iterations documented | Git commits |
| MH5 | Final scan: no HIGH/CRITICAL | Final report |
| MH6 | Guardrails enabled | Config file |
| MH7 | LiteLLM gateway deployed | `curl /health` |
| MH8 | 3 virtual keys với `max_budget` | Dashboard |
| MH9 | InsightHub routes through gateway | Audit log |
| MH10 | Cost dashboard Grafana | URL |
| MH11 | AWS Budgets alert | `aws budgets describe-budget` |
| MH12 | Threat model document | `security/threat-model.md` |

**Should-have:**
- CI/CD Promptfoo nightly cron
- CI/CD Promptfoo on PR (block merge if regression)
- Anthropic prompt caching enabled
- Semantic cache (Redis vector)
- Model routing: simple → Haiku, daily → Sonnet, complex → Opus
- PII detection input + output
- Fallback chain: Anthropic → Bedrock → Ollama

**Nice-to-have:**
- Custom Promptfoo plugin cho Vietnamese PII
- Llama Guard 3 sidecar
- EU AI Act compliance checklist
- Anomaly detection cho cost metric
- Multi-tenant cost attribution

### 10.5. Acceptance Criteria

```
[ ] cat security/promptfooconfig.yaml | yq .  → valid YAML
[ ] promptfoo redteam generate  → 50+ test cases
[ ] promptfoo redteam run  → initial report
[ ] [Fix iterations: ≥ 3 commits]
[ ] Final scan: no HIGH/CRITICAL
[ ] Guardrails config exists
[ ] curl http://litellm:4000/health  → 200
[ ] 3 virtual keys with max_budget
[ ] InsightHub uses LITELLM_API_KEY
[ ] Grafana "LLM Cost" panel  → cost rate
[ ] aws budgets describe-budgets  → "insighthub-llm-monthly"
[ ] cat security/threat-model.md  → 6+ threats
```

### 10.6. Rubric Day 6 — Security (12%) + FinOps (7%) = 19%

**Dim 6 — Security (12%):**

| Level | Score | Criteria |
|---|---|---|
| L1 | 0-4 | Promptfoo không chạy hoặc có CRITICAL unfixed |
| L2 | 5-7 | Promptfoo chạy nhưng có HIGH unfixed |
| L3 | 8-9 | Promptfoo no-HIGH. Threat model có. Guardrails enabled. |
| L4 | 10-12 | Pass OWASP LLM + Agentic Top 10. Guardrails layered. Red team comprehensive. PII detection. |

**Dim 7 — FinOps (7%):**

| Level | Score | Criteria |
|---|---|---|
| L1 | 0-2 | Không có cost report |
| L2 | 3-4 | Cost report > $10/tuần |
| L3 | 5-6 | Cost report < $5/tuần, có dashboard, gateway |
| L4 | 7 | Cost < $3/tuần + routing + gateway + budget alerts + attribution |

**Pass**: Cả 2 Dim L3.

### 10.7. Common Pitfalls

| Pitfall | Triệu chứng | Fix |
|---|---|---|
| **Promptfoo quota** | Rate limit | Separate test API key; reduce numTests |
| **Guardrail too strict** | Legitimate query blocked | Reduce strength HIGH → MEDIUM |
| **Gateway not enforcing budget** | Cost vọt past cap | Postgres DB required (SQLite limited) |
| **Virtual key bypass** | App uses ANTHROPIC_API_KEY direct | Audit code, replace |
| **Indirect injection still works** | After sanitization | Add NeMo Guardrails as second layer |
| **System prompt still leaks** | Despite hardening | Use Bedrock Guardrails PROMPT_ATTACK filter |
| **AWS Budgets reactive** | Alert 24h delay | Budget = soft alert. Hard cap at gateway |

### 10.8. Submission Format

```
Day 6 — <Your Name>

✓ Promptfoo config: <URL>
✓ Final scan report (no HIGH): <URL>
✓ Threat model: <URL>
✓ Guardrails config: bedrock-guardrail.json or nemo-config/
✓ LiteLLM config: <URL>
✓ Virtual keys (screenshot): <URL>
✓ Cost dashboard URL: <Grafana URL>
✓ AWS Budgets: aws budgets list-budgets output
```

### 10.9. Self-Check Questions

1. Promptfoo final scan có HIGH không? Mỗi HIGH ban đầu, fix thế nào?
2. 6 lớp Defense in Depth — cover được mấy lớp?
3. Threat model — 6 threats nào? Mitigation mỗi cái?
4. LiteLLM gateway có bao nhiêu virtual keys? Tổng budget cap?
5. Cost dashboard hiển thị gì? Cost/hour hiện tại?
6. Bedrock Guardrails (hoặc NeMo) — bạn enable filter nào? Why?
7. Indirect injection từ poisoned-doc — bạn discovered thế nào? Fix layer nào ngăn được?
8. Anthropic prompt caching — tiết kiệm bao nhiêu % cho system prompt?
9. Model routing — bao nhiêu % request route Haiku vs Sonnet?

---

## 11. Day 7 — Showcase & Final State

### 11.1. Day Context

**Đã có trước Day 7:**
- ✅ 6 ngày tích lũy 6+ artifact.
- ✅ Trainer chấm async → return rubric per dimension qua Slack DM **trước** Day 7.
- ✅ Bạn biết điểm trước buổi → Day 7 là **ăn mừng**, không phải thi.

**Sẽ làm Day 7:**
1. (15 bạn) Submit screencast 3' Loom trước Day 7 0h.
2. (5-6 bạn volunteer) Demo live 12' + Q&A.
3. (15 bạn) Gallery walk + voting 8 categories.
4. Wrap-up + 4 roadmap chọn 1.

### 11.2. Triết lý "Showcase, not Defense"

- Điểm số đến từ **artifact verify được** (chấm async).
- Demo chỉ là *trình diễn*, không phải cơ sở chấm.
- Nếu hoàn thành 6 daily artifact → bạn **đã đạt** trước Day 7.
- Day 7 = ăn mừng + peer learning + định hướng tiếp.

### 11.3. Final Project State Requirements

**Mọi học viên (15 bạn) phải có:**

| # | Artifact | Verify |
|---|---|---|
| 1 | Day 1: PR + CLAUDE.md đầy đủ | ingestion-worker tách |
| 2 | Day 2: `.mcp.json` 4+ servers | claude mcp list Connected |
| 3 | Day 3: Terraform pass checkov no-HIGH | `checkov -d infra/` clean |
| 4 | Day 3: CI/CD pipeline green | Workflow run ✓ |
| 5 | Day 4: Observability + 3 AI RCA | Grafana + reports |
| 6 | Day 5: ChatOps bot live | Bot answers 3 questions |
| 7 | Day 6: Promptfoo no-HIGH + threat model + cost dashboard | Files + dashboard |
| 8 | **Screencast 3' Loom (BẮT BUỘC 15 bạn)** | Loom URL |
| 9 | Cost report 1 tuần | < $5/tuần ideal |
| 10 | InsightHub LIVE accessible | `curl /health` → 200 |

### 11.4. Volunteer Demo Requirements (5-6 bạn)

- Slide demo ngắn (5-10 slides).
- Kịch bản 12 phút (10 demo + 2 Q&A).
- InsightHub running, sẵn sàng demo live.
- Demo show 6 thứ:
  1. AI prompt log
  2. Pipeline green
  3. Anomaly dashboard
  4. ChatOps bot live
  5. Security report (Promptfoo no-HIGH)
  6. Cost report

### 11.5. Demo Structure khuyến nghị (12 phút)

```
0:00-1:00   Use case + pain point (TẠI SAO làm InsightHub)
1:00-2:00   Architecture diagram (CÁCH bạn đã build)
2:00-3:00   AI workflow showcase (CLAUDE.md, prompt log)
3:00-5:00   Live demo: upload doc → ask question → trả lời thật
5:00-6:00   Pipeline + IaC (GitHub Actions green)
6:00-7:30   Observability (Grafana dashboard + 1 anomaly + RCA)
7:30-9:00   ChatOps bot live (hỏi 1-2 câu trong Slack)
9:00-10:00  Security + Cost (Promptfoo report + cost dashboard)
10:00-12:00 Q&A
```

### 11.6. Self-Checklist trước Day 7

```
ARTIFACT VERIFICATION
[ ] Day 1 PR merged or final: ingestion-worker tách
[ ] Day 2 .mcp.json 4+ servers Connected
[ ] Day 3 infra/ + pipeline green
[ ] Day 4 observability + 3 RCA reports
[ ] Day 5 chatops-bot deployed
[ ] Day 6 security no-HIGH + threat-model + cost dashboard
[ ] InsightHub LIVE: curl /health → 200

DAY 7 PREP
[ ] Screencast 3' Loom recorded
[ ] Loom URL submitted to Slack #day7-screencasts before 0h
[ ] Cost report 1 tuần aggregated
[ ] Self-evaluation form filled

DEMO READINESS (volunteer only)
[ ] Slide deck export PDF backup
[ ] Loom backup of full 12' demo
[ ] Network test on classroom
```

### 11.7. Gallery Walk — 8 Recognition Categories

Cả 15 deployment hiển thị song song. Mỗi người vote (max 2 categories):

1. **Best Architecture** — clear, scalable design
2. **Best Observability** — dashboard nhiều insight nhất
3. **Best Security** — defense-in-depth tốt nhất
4. **Best Cost Optimization** — token efficient nhất
5. **Best AI Integration** — AI workflow seamless nhất
6. **Best Bot UX** — ChatOps bot natural, useful
7. **Most Creative Feature** — surprise me!
8. **Best Documentation** — CLAUDE.md + README clear nhất

Multi-winner per category OK. Goal: nhiều bạn được công nhận, không chỉ top 3.

### 11.8. Submission Format Day 7

```
Day 7 — <Your Name>

✓ Final state verified: all 7 daily artifacts ✓
✓ Screencast 3': https://loom.com/<id>
✓ Self-evaluation form: <URL>
✓ Cost report 1 week: $<amount>
✓ Roadmap chosen: ☐ MLOps  ☐ Autonomous Agents  ☐ Security  ☐ A2A
✓ (Volunteer only) Slide deck: <URL>
```

### 11.9. Q&A — câu hỏi điển hình

Trainer/peers sẽ hỏi để **kiểm tra hiểu biết** (không phải bẫy):

| Pillar | Sample Q |
|---|---|
| Develop | "Tại sao chọn ARQ vs Celery cho queue?" |
| Develop | "Show me CLAUDE.md — section quan trọng nhất?" |
| Operate | "Anomaly threshold 3σ — vì sao? False positive rate?" |
| Operate | "RCA surprising finding nhất là gì?" |
| Govern | "OWASP entry quan trọng nhất cho InsightHub?" |
| Govern | "Cost target — bạn giữ < $5/week thế nào?" |
| Cross | "Nếu có thêm 1 ngày, bạn sẽ add gì?" |

**Trả lời pattern:**
- Cite specific data/code (not vague).
- Acknowledge trade-offs.
- Mention alternatives considered.
- "I don't know" is OK — better than vibe answer.

---

# Phần 3 — References

## 12. Self-Evaluation Form

Nộp trước Day 7 0h qua link Google Form trainer sẽ gửi:

```
1. Tổng cộng tôi nộp được bao nhiêu artifact (1-7)?

2. Artifact nào tôi tự đánh giá Level 4 (excellence)?

3. Artifact nào tôi tự đánh giá < Level 3?

4. Pillar nào tôi học nhiều nhất:
   ☐ A. Develop with AI
   ☐ B. Operate with AI
   ☐ C. Govern AI

5. Tool nào tôi sẽ tiếp tục dùng sau khoá?

6. Câu hỏi tôi muốn hỏi trainer Day 7?

7. Roadmap tôi chọn đi tiếp (1/4):
   ☐ MLOps Deep Dive
   ☐ Autonomous Coding Agents (Devin, Replit Agent)
   ☐ Agentic Security & Compliance
   ☐ A2A Protocol & Multi-Agent Systems

8. Feedback cho trainer (anonymous OK):
   - 3 điều tôi thấy giá trị nhất:
   - 1 điều tôi muốn thay đổi:
   - Suggest cho khoá sau:
```

---

## 13. Continued Learning — 4 Roadmaps

Sau Day 7, chọn 1 trong 4 hướng để dấn sâu 6-12 tháng tới:

### Roadmap 1: 🆕 MLOps Deep Dive

**Cho ai**: muốn vào ML platform / AI infrastructure thật.

**Stack học:**
- **MLflow** — model registry, experiment tracking
- **Kubeflow Pipelines** — orchestrate ML pipeline trên K8s
- **SageMaker Model Registry** — managed AWS
- **DVC** — Data Version Control
- **Feast / Tecton** — Feature Store
- **TorchServe / Triton / vLLM** — model serving

**Use case**: bạn join team có model riêng (không chỉ LLM API); production có CV/NLP/recommender; compliance industry cần model lineage.

**Resource**: bonus handout MLOps reference 30-page (request trainer); book "Designing Machine Learning Systems" — Chip Huyen.

### Roadmap 2: Autonomous Coding Agents

**Cho ai**: muốn explore "giao task rồi đi làm việc khác".

**Stack học:**
- **Devin** — full autonomous coding agent
- **Replit Agent 3** — full-stack scaffolder
- **Codex Cloud** — OpenAI async
- **Cursor Cloud Agents**

**Pattern**: "Codex for volume, Claude for depth" — agent cloud async cho bulk task, Claude Code cho deep refactor.

**Use case**: bulk migration (50+ file similar pattern), test coverage generation, library upgrade.

### Roadmap 3: Agentic Security & Compliance

**Cho ai**: muốn chuyên về AI security, audit, governance.

**Stack học:**
- **OWASP ASI Top 10** — memory poisoning, rogue agents, cascade trust
- **Agentic SAST** — SAST cho code có AI agent
- **A2A Protocol Security** — auth, identity, capability cards
- **MITRE ATLAS** — adversarial ML taxonomy
- **EU AI Act** compliance (enforcement 8/2026)
- **NIST AI RMF 1.0**
- **ISO 42001** AI management certification

**Use case**: build AI system trong regulated industry; security audit AI apps; AI Reliability Engineer role.

### Roadmap 4: A2A Protocol & Multi-Agent Systems

**Cho ai**: muốn build hệ thống nhiều agent cộng tác.

**Stack học:**
- **A2A Protocol** — Agentic AI Foundation spec
- **Agent Capability Cards** — discovery & trust
- **LangGraph / AutoGen / CrewAI** — multi-agent frameworks
- **Temporal / Restate** — workflow orchestration

**Use case**: cross-team agent collaboration (security agent + perf agent); cross-org delegation; multi-step long-running workflows.

---

## Career Path

```
DevOps Engineer  →  Platform Engineer  →  AI Reliability Engineer (AIRE)
                 \
                  →  MLOps Engineer / AI Platform Engineer
                 \
                  →  AI Security Engineer
                 \
                  →  AI FinOps Specialist
```

Vai trò mới đang hình thành 2026-2027:
- **AI Reliability Engineering (AIRE)** — đảm bảo chất lượng/công bằng/minh bạch hệ thống AI production
- **AI Platform Engineer** — build internal platform cho team dùng AI
- **AI Security Engineer** — focus red team + governance LLM systems
- **AI FinOps Specialist** — chuyên cost optimization cho LLM/agent

---

## Roadmap 6-12 tháng sau khoá

**3 tháng đầu** — Apply lessons vào current job:
- Setup Claude Code BYOK cho team
- Build 1 MCP server cho tool nội bộ
- Audit 1 LLM feature đang có với Promptfoo
- Setup cost dashboard cho LLM spending team

**6 tháng tiếp** — Deepen expertise:
- Đào sâu 1 trong 4 roadmap (chọn theo interest)
- Contribute open-source (MCP server, framework, doc)
- Lead 1 AI-augmented project ở team

**12 tháng** — Thought leadership:
- Talk tại meetup / conference
- Write blog series về journey
- Mentor team mới adoption AI-Native
- Eligible cho AI Reliability Engineer / Platform Engineer role

---

## Community & Continuous Learning

**Communities to join:**
- Anthropic Discord / forum
- Modelcontextprotocol GitHub discussions
- DevOps Vietnam Slack / Facebook groups
- Reddit r/LocalLLaMA, r/devops, r/MachineLearning

**Newsletters:**
- **Latent Space** — AI engineering
- **The Pragmatic Engineer** — software engineering
- **The Cloudcast** — cloud architecture
- **DevOps'ish** — DevOps weekly

**Books recommended:**
- **"AI Engineering"** — Chip Huyen (2026)
- **"Building LLM Applications"** — multiple authors
- **"The DevOps Handbook"** — Kim, Humble, Debois, Willis (classic)

**Office hours alumni:**
- Monthly với trainer Cong (schedule TBD)
- Alumni Slack workspace invite Day 7

---

## 14. Glossary

| Term | Định nghĩa |
|---|---|
| **Agentic loop** | Vòng lặp perceive → reason → act → observe của AI agent |
| **Agentic AIOps** | AIOps Gen 3 với LLM agent tự diagnose + remediate |
| **CLAUDE.md** | File constitution cho project, Claude Code đọc mỗi phiên (≤ 200 dòng) |
| **Constraint-first prompt** | Pattern prompt 4-part: Mục tiêu + Ràng buộc + Tiêu chí + Ví dụ |
| **Daily artifact** | Sản phẩm verify được mỗi Day, submit qua Slack |
| **Defense in Depth** | Phòng vệ nhiều lớp (input sanitize + guardrails + prompt hardening + ...) |
| **Drift** | Production data thay đổi vs training data → model dần kém chính xác |
| **Evidence-first** | RCA prompt pattern force cite specific metric + timestamp |
| **HITL** | Human-in-the-Loop — AI suggest, human approve, system execute |
| **InsightHub** | Running project RAG Notebook xuyên suốt 7 ngày |
| **IRSA** | IAM Role for Service Account (EKS pattern) |
| **MCP** | Model Context Protocol — "USB-C cho AI agent" |
| **MTTR** | Mean Time To Resolution |
| **OIDC AWS** | OpenID Connect — no long-lived AWS access keys |
| **OWASP LLM Top 10** | Khung rủi ro cho ứng dụng LLM (2025 v) |
| **OWASP ASI Top 10** | Khung rủi ro cho agentic application (2026 v) |
| **Permission 3-tier** | Auto-allow (read) / Ask-confirm (write) / Always-deny + token (destructive) |
| **Prompt caching** | Anthropic feature cache prefix prompt (90% discount cached portion) |
| **Promptfoo** | OSS red team tool cho LLM (OWASP preset built-in) |
| **RED method** | Rate / Errors / Duration — instrument cho service layer |
| **Running project** | InsightHub — 1 project xuyên suốt 7 ngày, solo tracks |
| **Solo tracks** | 15 học viên làm độc lập, không nhóm |
| **Spec-driven dev** | Viết spec có cấu trúc trước, AI sinh code theo |
| **Three-layer defense** | IaC pattern: AI generate → human review → policy gate |
| **USE method** | Utilization / Saturation / Errors — instrument cho resource layer |

---

## Lời kết

7 ngày qua sẽ đi từ một app local đơn giản tới deployment production-grade — observable, secure, cost-optimized.

Quan trọng hơn cả artifact: bạn sẽ rèn được **tư duy AI-Native** — biết khi nào giao việc cho AI, khi nào giữ phán đoán cho mình, và làm thế nào để tốc độ AI không biến thành nợ kỹ thuật hay nợ bảo mật.

Đó là năng lực thị trường 2026 đang trả giá cao nhất.

**Hẹn gặp lại trong Module 7.** 🚀

---

*Running Project Specification v3.0 Final · Module 7 — AI-Native DevOps · Student Edition*
*Trainer: Trần Mạnh Cong · Tháng 5/2026*
