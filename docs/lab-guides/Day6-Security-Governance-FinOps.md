# Lab Guide — Day 6: LLM Security, Governance & FinOps

> **Module 7 — AI-Native DevOps** · Pillar C: Govern AI
> Thời lượng: 2.5 giờ (150 phút) · Running project: **InsightHub**

---

## Mục tiêu buổi học

Kết thúc Day 6, học viên có thể:

1. Áp dụng OWASP LLM Top 10 (2025) + OWASP Agentic AI Top 10 vào kiến trúc AI-augmented.
2. Red-team chính InsightHub bằng Promptfoo — phát hiện indirect prompt injection.
3. Triển khai defense-in-depth: guardrails, sanitization, least-privilege, audit.
4. Quản lý cost LLM: gateway, model routing, budget alerts.

**Daily Artifact:** Promptfoo OWASP scan report (no HIGH) + threat model document + cost dashboard.

---

## Chuẩn bị trước buổi

- [ ] ChatOps bot (Day 5) đã chạy
- [ ] Promptfoo đã cài (`promptfoo --version`)
- [ ] Đã đọc OWASP LLM Top 10 (2025) + Agentic AI Top 10
- [ ] Có 1 file tài liệu "sạch" để test

---

## Segment 1 — Recap & Hook (10 phút)

- "Suốt 5 ngày ta cho AI agent ngày càng nhiều quyền: đọc code, chạm cluster, query Prometheus, giờ cả Slack bot có thể `kubectl`. Quyền lực = trách nhiệm."
- Hook — case thật: **EchoLeak (CVE-2025-32711, CVSS 9.3)** — zero-click prompt injection trong M365 Copilot, lặng lẽ rò rỉ dữ liệu SharePoint/Teams chỉ bằng 1 email, không cần user click.
- "InsightHub cho upload tài liệu. Tài liệu = input không tin cậy. Hôm nay ta tấn công chính InsightHub của mình."

---

## Segment 2 — Concept: OWASP LLM & Agentic AI Top 10 (45 phút)

### 2.1. OWASP LLM Top 10 (2025) — 5 rủi ro trọng tâm

| ID | Rủi ro | Liên quan InsightHub |
|---|---|---|
| **LLM01** | Prompt Injection (#1) | Tài liệu upload = vector indirect injection |
| **LLM02** | Sensitive Information Disclosure | Rò rỉ nội dung tài liệu / system prompt |
| **LLM05** | Improper Output Handling | Output LLM dùng thẳng không validate |
| **LLM06** | Excessive Agency | ChatOps bot có quá nhiều quyền |
| **LLM08** | Vector & Embedding Weaknesses | Đầu độc vector store (RAG poisoning) |

### 2.2. Direct vs Indirect Prompt Injection

- **Direct:** kẻ tấn công gõ payload thẳng vào câu hỏi.
- **Indirect:** payload giấu trong nội dung bên ngoài (tài liệu, web, email) mà LLM đọc sau đó. **Nguy hiểm hơn** — vì tổ chức thường coi knowledge base là "đáng tin".

Điểm cốt lõi (UK NCSC, OWASP): LLM **không tách bạch** được "instruction" và "data" trong prompt. Coi prompt injection như SQL injection là sai lầm — không có cơ chế tách cứng.

### 2.3. OWASP Agentic AI Top 10

Ra mắt Black Hat EU 2025. Các rủi ro mới khi AI là *agent* có tool: Goal Hijack, Tool Misuse, Identity Spoofing, Memory Poisoning, Cascade Attack. Khi "read" của agent biến thành "write/exfil/action" (vì agent có tool), blast radius lớn hơn nhiều.

---

## Segment 3 — Best Practice: Defense in Depth (30 phút)

### 3.1. Các lớp phòng vệ

```
Lớp 1: Input sanitization   → lọc payload, xử lý hidden text
Lớp 2: Guardrails           → Bedrock Guardrails / NeMo / Llama Guard
Lớp 3: Prompt hardening     → tách instruction/data bằng cấu trúc rõ (<context>)
Lớp 4: Least-privilege tool → agent chỉ có đúng tool cần, deny by default
Lớp 5: Output validation    → schema chặt, tool-call allowlist
Lớp 6: Audit + red team     → log đầy đủ, quét định kỳ
```

### 3.2. Ship gate trước khi launch LLM feature

- [ ] AI có least-privilege access (deny by default)
- [ ] Hành động rủi ro cao cần human approval
- [ ] Instruction và untrusted content tách bạch, delimit rõ
- [ ] RAG prompt dùng template đã hardened
- [ ] Input filtering xử lý hidden text / obfuscation
- [ ] Output validation deterministic (schema, allowlist)
- [ ] Logging bật, searchable, được review
- [ ] Chạy red-team + indirect-injection test định kỳ

### 3.3. InsightHub đã có gì sẵn

File `api/app/services/llm.py` đã tách `<context>` khỏi system prompt — đây là prompt hardening lớp 3. Nhưng chưa đủ — hôm nay sẽ test xem nó chịu được tới đâu.

---

## Segment 4 — Red Team Lab + FinOps (50 phút)

### Phần A — Red Team InsightHub (35 phút)

**Bước 1 — Tấn công indirect injection thủ công (10 phút)**

Trong `sample-docs/` có 3 file. Học viên ingest tất cả vào InsightHub, rồi đặt vài câu hỏi. **Một trong các file chứa indirect prompt injection** — học viên tự phát hiện file nào và quan sát RAG pipeline có bị tác động không.

Câu hỏi phân tích: vì sao đoạn payload bị retrieval kéo vào context? System prompt có chống được không?

**Bước 2 — Promptfoo OWASP scan (15 phút)**

Hoàn thiện `security/promptfooconfig.yaml` (skeleton đã có). Prompt cho Claude Code:

```
Hoàn thiện security/promptfooconfig.yaml để red-team InsightHub.
Bật các plugin OWASP phù hợp với 1 RAG app: prompt-injection,
indirect-prompt-injection, rag-poisoning, pii, excessive-agency.
Strategies: basic, prompt-injection. numTests hợp lý cho lab.
Giải thích mỗi plugin test gì.
```

Chạy:

```bash
cd security
promptfoo redteam run
promptfoo redteam report
```

Đọc báo cáo — phân loại lỗ hổng theo severity.

**Bước 3 — Vá lỗ hổng (10 phút)**

Với mỗi lỗ HIGH, prompt cho Claude Code vá. Ví dụ hướng vá:
- Sanitize chunk trước khi đưa vào context.
- Hardening system prompt mạnh hơn.
- Thêm guardrails (Bedrock Guardrails hoặc NeMo Guardrails).
- Output validation.

Chạy lại `promptfoo redteam run` → mục tiêu **no HIGH severity**.

### Phần B — FinOps cho LLM (15 phút)

**Vì sao quan trọng:** InsightHub có 2 loại LLM call — embedding (mỗi chunk) + generation (mỗi câu hỏi). Không kiểm soát → bill shock.

**Bước 1 — Cost visibility:** InsightHub đã expose `insighthub_llm_tokens_total` và `insighthub_embedding_tokens_total`. Thêm panel cost vào Grafana dashboard:

```
Thêm panel vào dashboard observability/: ước tính cost LLM theo thời gian
dựa trên insighthub_llm_tokens_total (input/output) và đơn giá model.
```

**Bước 2 — LLM gateway (giới thiệu):** Requesty / LiteLLM / Helicone — gateway đứng giữa app và LLM provider, cho: cost tracking tập trung, model routing (câu đơn giản → model rẻ, câu khó → model mạnh), failover.

**Bước 3 — Budget alert:** thiết lập AWS Budgets alert cho chi tiêu AI service (nếu dùng Bedrock), hoặc spend limit trong Anthropic Console.

---

## Segment 5 — Threat Model (15 phút)

Học viên viết 1 threat model document ngắn cho InsightHub: liệt kê tài sản (vector store, API key, cluster access), các vector tấn công (theo OWASP), biện pháp phòng vệ đã áp dụng.

---

## Daily Artifact — Checklist nộp

| # | Artifact | Cách verify |
|---|---|---|
| 1 | Promptfoo scan report | `promptfoo redteam report` — no HIGH severity |
| 2 | Lỗ hổng đã vá | Diff code cho thấy đã vá; scan lại sạch |
| 3 | Threat model document | Liệt kê tài sản + vector tấn công + phòng vệ |
| 4 | Cost dashboard | Panel cost trong Grafana |

---

## Troubleshooting

| Triệu chứng | Nguyên nhân | Xử lý |
|---|---|---|
| `promptfoo redteam run` lỗi target | URL/body config sai | Kiểm tra InsightHub `/chat` đang chạy |
| Scan không tìm thấy lỗ hổng nào | Plugin chưa bật | Kiểm tra `plugins:` không rỗng |
| Indirect injection không trigger | File poisoned chưa được ingest | Đảm bảo đã upload đủ sample-docs |
| Cost panel "No data" | Token metric = 0 | Cần có chat traffic thật để sinh token |
| Vá xong vẫn còn HIGH | Vá chưa đúng lớp | Đối chiếu lớp phòng vệ — có thể cần guardrails |

---

## Homework (chuẩn bị Day 7)

1. Hoàn thiện InsightHub: đảm bảo đủ 6 artifact (Day 1-6).
2. 5-6 bạn volunteer chuẩn bị demo 12 phút.
3. **Tất cả 15 bạn** quay screencast 3 phút (Loom) nộp trước.
4. Tổng hợp cost report 1 tuần.
5. Tự rà self-checklist 6 artifact.

---

## Ghi chú cho Trainer

- Skeleton `security/promptfooconfig.yaml` đã có sẵn — học viên không viết from scratch.
- File `sample-docs/huong-dan-nguoi-moi.md` chứa indirect injection — KHÔNG nói trước file nào, để học viên tự phát hiện. Xem `sample-docs/README.md`.
- Plugin Promptfoo thay đổi nhanh — verify tên plugin chính xác 1 ngày trước tại promptfoo.dev/docs/red-team.
- Red team lab chạy trong sandbox, dùng API key dummy cho InsightHub test — tránh rò rỉ key thật (Risk R9).
- FinOps chỉ 15 phút — đủ giới thiệu khái niệm + thêm panel. Không sa đà vào cấu hình gateway phức tạp.
- Đây là buổi "đắt giá" nhất khóa — nhấn mạnh: không trung tâm nào khác dạy đủ phần này.
