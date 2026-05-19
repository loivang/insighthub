# Pre-Reading — Day 6: LLM Security, Governance & FinOps

> **Module 7 — AI-Native DevOps** · Pillar C: Govern AI
> Tài liệu đọc trước buổi học. Thời gian đọc ước tính: 45-55 phút.
> Mục tiêu: hiểu lý thuyết bảo mật LLM/agent và quản trị chi phí để vận hành AI có trách nhiệm.

---

## Mục lục

1. [Bối cảnh: quyền lực đi kèm rủi ro](#1-bối-cảnh)
2. [Concept: vì sao bảo mật LLM khác bảo mật web truyền thống](#2-concept)
3. [OWASP LLM Top 10 (2025)](#3-owasp-llm)
4. [OWASP Agentic Top 10 (2026)](#4-owasp-agentic)
5. [Prompt Injection — sâu hơn](#5-prompt-injection)
6. [Defense in Depth — kiến trúc phòng vệ](#6-defense-in-depth)
7. [LLM FinOps — quản trị chi phí](#7-finops)
8. [Implementation: red-team & cost control InsightHub](#8-implementation)
9. [Best Practices](#9-best-practices)
10. [Case Study](#10-case-study)
11. [Thuật ngữ & Đọc thêm](#11-thuật-ngữ)

---

## 1. Bối cảnh

### 1.1. Suốt khóa học, ta đã trao cho AI ngày càng nhiều quyền

Day 1: AI đọc & sửa code. Day 2: AI chạm cluster qua MCP. Day 4: AI query Prometheus. Day 5: AI bot có thể `kubectl`. **Quyền lực tích lũy = bề mặt tấn công tích lũy.** Day 6 là buổi "trả nợ" — đảm bảo mọi quyền đó được kiểm soát.

### 1.2. Con số

- Thị trường LLM security platform: **$2.37 tỷ (2024)**, CAGR 21.4% tới 2033.
- **>30 ca system prompt leakage** được ghi nhận chỉ trong 2024 — lộ API key, workflow vận hành.
- 37% doanh nghiệp chi **>$250,000/năm** cho LLM API; 72% dự kiến hóa đơn còn tăng.
- Agent gọi LLM **gấp 3-10 lần** chatbot thường — một request người dùng kích hoạt plan, tool selection, execution, verification, response.

### 1.3. Case thật — EchoLeak

**CVE-2025-32711 (EchoLeak)** — zero-click prompt injection trong Microsoft 365 Copilot, CVSS **9.3**. Lặng lẽ rò rỉ dữ liệu SharePoint/Teams chỉ bằng một email được tạo khéo — không cần phishing link, không cần user click. Đây là "trần" của loại tấn công này: tự động hoàn toàn, không tương tác.

---

## 2. Concept — bảo mật LLM khác bảo mật web truyền thống

### 2.1. Vì sao khác

Lỗ hổng web truyền thống (SQLi, XSS) dev đã chiến đấu hàng chục năm. LLM **khác về bản chất**:

- Xử lý **ngôn ngữ tự nhiên** — không có ranh giới cứng giữa "lệnh" và "dữ liệu".
- Sinh output **không đoán trước được**.
- Thường có quyền truy cập **dữ liệu nhạy cảm** và **hành động mạnh**.

### 2.2. Điểm cốt lõi — không tách được instruction và data

> UK NCSC cảnh báo: coi prompt injection như SQL injection là **nguy hiểm**, vì LLM **không** thực thi sự tách bạch chắc chắn giữa "instruction" và "data" trong prompt.

SQLi có thể vá triệt để bằng parameterized query — tách lệnh khỏi dữ liệu. Prompt injection **không có** giải pháp triệt để tương đương, vì LLM xử lý cả hai trong cùng một dòng văn bản. Đây là lý do phải dùng **defense-in-depth** thay vì một "viên đạn bạc".

### 2.3. Hai khung OWASP cần biết

| Khung | Phát hành | Cho |
|---|---|---|
| **OWASP Top 10 for LLM Applications 2025** | 18/11/2024 | Ứng dụng LLM single-turn |
| **OWASP Top 10 for Agentic Applications 2026 (ASI)** | 12/2025 | Hệ thống agent tự chủ |

---

## 3. OWASP LLM Top 10 (2025)

### 3.1. Toàn bộ 10 rủi ro

| ID | Rủi ro |
|---|---|
| LLM01 | Prompt Injection |
| LLM02 | Sensitive Information Disclosure |
| LLM03 | Supply Chain |
| LLM04 | Data and Model Poisoning |
| LLM05 | Improper Output Handling |
| LLM06 | Excessive Agency |
| LLM07 | System Prompt Leakage *(mới 2025)* |
| LLM08 | Vector and Embedding Weaknesses *(mới 2025)* |
| LLM09 | Misinformation |
| LLM10 | Unbounded Consumption |

### 3.2. Hai mục mới 2025 — vì sao được thêm

- **LLM07 — System Prompt Leakage:** >30 ca ghi nhận năm 2024, system prompt bị trích xuất làm lộ API key và workflow vận hành.
- **LLM08 — Vector and Embedding Weaknesses:** thêm vào do RAG được áp dụng rộng — vector store trở thành bề mặt tấn công mới (RAG poisoning).

### 3.3. Năm rủi ro trọng tâm cho InsightHub (một RAG app)

| ID | Vì sao liên quan InsightHub |
|---|---|
| **LLM01** Prompt Injection | Tài liệu upload = vector indirect injection |
| **LLM02** Sensitive Info Disclosure | Rò rỉ nội dung tài liệu / system prompt |
| **LLM05** Improper Output Handling | Output LLM dùng thẳng không validate |
| **LLM06** Excessive Agency | ChatOps bot có quá nhiều quyền |
| **LLM08** Vector/Embedding Weaknesses | Đầu độc vector store |

### 3.4. LLM06 — Excessive Agency được mở rộng

Mục này được mở rộng năm 2025 để phản ánh kiến trúc agentic — LLM được trao nhiều tự chủ hơn → cần giám sát cẩn thận để ngăn hành động ngoài ý muốn. Đây chính là cầu nối sang khung Agentic Top 10.

---

## 4. OWASP Agentic Top 10 (2026)

### 4.1. Vì sao cần khung riêng

Khi LLM trở thành **agent** — tự plan, quyết định, thực thi đa bước với tool — khung LLM Top 10 *không đủ*. Khả năng agent **chain hành động** và **tự chủ** nghĩa là một lỗ hổng nhỏ (vd prompt injection đơn giản) có thể **cascade** thành compromise toàn hệ thống, data exfiltration, thiệt hại tài chính.

> Thách thức không còn là bảo mật *một model call*, mà là bảo mật cả một *workflow* động, phức tạp, khó đoán.

### 4.2. Khung ASI (Agentic Security Issue)

OWASP phát hành **ASI Top 10** (12/2025) — định danh chính thức tiền tố **ASI**, từ ASI01 đến ASI10. Tập trung vào lỗi từ: goal misalignment, tool misuse, delegated trust, inter-agent communication, persistent memory, emergent autonomous behavior.

| Ví dụ rủi ro ASI | Mô tả |
|---|---|
| **ASI01 — Agent Goal Hijack** | Kẻ tấn công chiếm mục tiêu của agent |
| **Tool Misuse** | Agent bị lừa lạm dụng tool |
| **Identity Spoofing** | Giả mạo danh tính trong hệ multi-agent |
| **Memory Poisoning** | Đầu độc bộ nhớ bền vững của agent |
| **ASI10 — Rogue Agents** | Agent "phản loạn" |

### 4.3. Bốn đặc tính tạo rủi ro mới của agentic

1. **Autonomous decision-making** — agent tự plan, reason, execute.
2. **Tool integration** — agent compose & invoke tool động → tool chain là bề mặt tấn công mới.
3. **Persistent memory** — agent giữ context qua nhiều session → dễ bị memory poisoning lâu dài.
4. **Inter-agent communication** — multi-agent trao đổi message → vector thao túng, khai thác trust mới.

---

## 5. Prompt Injection — sâu hơn

### 5.1. Direct vs Indirect

| Loại | Cơ chế | Nguy hiểm |
|---|---|---|
| **Direct** | Kẻ tấn công gõ payload thẳng vào chat/API input | Dễ phát hiện hơn |
| **Indirect** | Payload giấu trong nội dung ngoài (tài liệu, web, email, metadata, tool description) mà model đọc sau | **Nguy hiểm hơn** — tổ chức thường coi knowledge base là "đáng tin" |

### 5.2. Vì sao indirect đặc biệt nguy hiểm với RAG

> Với hệ RAG, test tác động lớn nhất là **inject vào mọi nguồn nội dung mà hệ thống ingest**.

Khi model có tool access, một thao tác "read" (đọc tài liệu độc) biến thành "write/exfil/action". Payload có thể giấu bằng **hidden text / invisible formatting** — khó phát hiện bằng mắt. Lưu ý: prompt injection *không cần human-readable* — chỉ cần model parse được.

### 5.3. Agent hijacking scale theo tool access

Một AI assistant có tool email + file + web, khi xử lý nội dung do kẻ tấn công kiểm soát, sẽ làm theo lệnh được inject: exfiltrate data, gửi message, gọi API — tất cả mà người dùng không thấy gì. EchoLeak chứng minh khai thác zero-click, tự động hoàn toàn của loại này đã chạm hệ thống production.

### 5.4. RAG/fine-tuning KHÔNG vá được prompt injection

OWASP nêu rõ: RAG và fine-tuning làm output *liên quan và chính xác hơn*, nhưng nghiên cứu cho thấy chúng **không vá hoàn toàn** lỗ hổng prompt injection.

---

## 6. Defense in Depth — kiến trúc phòng vệ

Vì không có "viên đạn bạc", phải xếp nhiều lớp:

```
Lớp 1: Input sanitization   → lọc payload, xử lý hidden text/obfuscation
Lớp 2: Guardrails           → Bedrock Guardrails / NeMo Guardrails / Llama Guard
Lớp 3: Prompt hardening     → tách instruction/data bằng cấu trúc rõ (delimiter)
Lớp 4: Least-privilege tool → agent chỉ có đúng tool cần, deny by default
Lớp 5: Output validation    → schema chặt, tool-call allowlist, deterministic
Lớp 6: Audit + red team     → log đầy đủ, quét OWASP định kỳ
```

### 6.1. Ship gate — checklist trước khi launch LLM feature

- [ ] AI có least-privilege access tới data và tool (**deny by default**)
- [ ] Hành động rủi ro cao cần **human approval** (payment, gửi message, data export)
- [ ] Instruction và untrusted content **tách bạch, delimit rõ**
- [ ] RAG prompt dùng **template đã hardened**
- [ ] Input filtering xử lý **hidden text / obfuscation**
- [ ] Output validation **deterministic** khi có thể (schema chặt, tool-call allowlist)
- [ ] Logging **bật, searchable, được review**
- [ ] Chạy **red-team + indirect-injection test** định kỳ, map theo taxonomy đã biết

### 6.2. Đối với agentic — kiểm soát thêm

- Least-privilege cho **mọi tool access**.
- Human-in-the-loop cho thao tác nhạy cảm.
- **Capability sandboxing** — cô lập năng lực agent.
- Ưu tiên **hành động đảo ngược được** (reversible).
- Fine-grained tool permissioning, policy-based control, continuous monitoring tool usage.

### 6.3. Công cụ phòng vệ runtime

| Loại | Công cụ |
|---|---|
| Guardrails | AWS Bedrock Guardrails, NVIDIA NeMo Guardrails, Llama Guard |
| Constitutional Classifiers | Anthropic — phân loại input/output theo "hiến pháp" |
| Instruction Hierarchy | OpenAI — phân cấp ưu tiên instruction |
| Red-team framework | Promptfoo, DeepTeam, garak, PyRIT |

---

## 7. LLM FinOps — quản trị chi phí

### 7.1. Vì sao cost là mối quan tâm kỹ thuật hạng nhất

Agent không bị kiểm soát giải một task software engineering có thể tốn **$5-8/task** chỉ tiền API. Ở quy mô lớn, đây là vấn đề business-critical. Năm 2026, team ship hệ thống agent bền vững coi **cost ngang hàng latency và reliability**.

### 7.2. Token economics — bất đối xứng input/output

- Tỷ lệ cost output:input trung vị ~**4:1**, model reasoning cao cấp tới **8:1**.
- Chênh lệch giá giữa các model **khổng lồ** — task route tới frontier model có thể tốn **190x** so với model nhỏ nhanh.

Hệ quả kiến trúc: nén output, dùng JSON mode để tránh free-text dài dòng, tránh chain-of-thought không cần thiết.

### 7.3. Bốn trụ cột quản trị chi phí agent

| Trụ cột | Cách làm |
|---|---|
| **Caching** | Semantic cache (GPTCache, Redis vector) — câu hỏi tương tự dùng lại response. Tới 10x giảm cost |
| **Model routing** | Câu đơn giản → model rẻ; câu khó → model mạnh. Giảm 20-60% cost |
| **Prompt compression** | LLMLingua nén prompt tới 20x; extractive summarization RAG chunk trước khi inject |
| **FinOps tooling** | Gateway tracking, budget enforcement, observability |

### 7.4. LLM Gateway — tầng trung gian

> Gateway đặt giữa ứng dụng và LLM provider, can thiệp mọi request, áp logic tiết kiệm cost **trước khi token bị tiêu**.

| Gateway | Đặc điểm |
|---|---|
| **LiteLLM** | Open-source, Python, 100+ provider, OpenAI-compatible. Spend tracking per key/team. Phổ biến nhất cho prototyping |
| **Bifrost** | Go runtime, overhead ~11µs, hierarchical budget, MCP gateway, Prometheus metrics |
| **Helicone** | Thiên observability, one-line setup, free tier rộng |
| **Cloudflare AI Gateway** | Managed, edge network, không cần infra |
| **Portkey** | Cost tracking per-request, budget limit |

Một gateway tốt trả lời 4 câu real-time: **ai chi gì, model nào, ngân sách nào, kết quả gì.**

### 7.5. Routing là kỹ thuật VÀ quản trị tài chính

Engineering định nghĩa classification logic + SLA safeguard. FinOps monitor blended cost + enforce budget. Routing vừa là tối ưu kỹ thuật vừa là chiến lược governance tài chính.

### 7.6. Tracking — observability cho cost

Stack observability đã trưởng thành để có chiều cost: Langfuse/Traceloop (trace-level cost attribution), Datadog LLM Observability, Vantage (có MCP server để agent tự query cost). Nhiều team export token usage từ provider API → dashboard Grafana/Metabase.

### 7.7. Anthropic Usage & Cost API

Anthropic cung cấp Usage/Cost API để truy vấn chi tiêu. Console cũng cho đặt spend limit — biện pháp đơn giản nhất chống bill shock.

---

## 8. Implementation — red-team & cost control InsightHub

### 8.1. Red-team InsightHub bằng Promptfoo

Promptfoo là CLI/library/CI-component cho test-driven LLM development. Quét >50 loại lỗ hổng: jailbreak, injection, RAG poisoning, compliance.

Plugin quan trọng cho 1 RAG app:
- `prompt-injection` — LLM01 direct
- `indirect-prompt-injection` — LLM01 indirect (qua tài liệu RAG)
- `rag-poisoning` — đầu độc retrieval
- `pii` — rò rỉ thông tin cá nhân
- `excessive-agency` — LLM06

### 8.2. InsightHub đã có gì sẵn

- `api/app/services/llm.py` đã tách `<context>` khỏi system prompt — prompt hardening lớp 3.
- `sample-docs/` chứa một tài liệu có **indirect prompt injection** cố ý — học viên tự phát hiện.
- `api/app/core/metrics.py` đã expose `insighthub_llm_tokens_total` (input/output) + `insighthub_embedding_tokens_total` — nền cho cost dashboard.

### 8.3. Cost của InsightHub

InsightHub có 2 loại LLM call: **embedding** (mỗi chunk khi ingest) + **generation** (mỗi câu hỏi). Không kiểm soát → bill shock. Quy trình Day 6: thêm panel cost vào Grafana dựa trên token metric + đơn giá model; giới thiệu gateway + model routing; đặt budget alert.

---

## 9. Best Practices

### 9.1. Defense in depth — không có viên đạn bạc

Vì LLM không tách được instruction/data, phải xếp nhiều lớp. Bỏ lớp nào cũng để lọt một loại tấn công.

### 9.2. Least-privilege, deny by default

AI chỉ có đúng tool/data cần. Đây là mitigation hiệu quả nhất cho Excessive Agency và Agent hijacking.

### 9.3. Treat knowledge base là untrusted

Đừng coi tài liệu upload là "đáng tin". Mọi nội dung ingest đều là untrusted content — sanitize, delimit rõ trong context.

### 9.4. Red-team định kỳ, map taxonomy

Chạy red-team + indirect-injection test thường xuyên, map theo OWASP / MITRE ATLAS — không phải test một lần rồi quên.

### 9.5. Cost là first-class concern

Đặt cost ngang latency và reliability. Hard token budget limit ở tầng framework/gateway. Daily monitoring, không phải monthly reconciliation.

### 9.6. Model routing đúng cách

Câu đơn giản → model rẻ. NHƯNG: routing sai có thể hại chất lượng — luôn có escalation validation và test.

### 9.7. Anti-patterns

| Anti-pattern | Hậu quả |
|---|---|
| Tin RAG/fine-tuning vá được prompt injection | Vẫn bị khai thác |
| Coi knowledge base là trusted | Indirect injection lọt thẳng |
| Agent full quyền tool | Một injection → cascade compromise |
| Output LLM dùng thẳng không validate | Improper Output Handling (LLM05) |
| Mọi request → frontier model | Cost gấp tới 190x không cần thiết |
| Monthly reconciliation thay vì daily | Phát hiện cost vọt quá muộn |
| Red-team một lần rồi quên | Lỗ hổng mới không được bắt |

---

## 10. Case Study

### 10.1. Red-team chính InsightHub — bài Day 6

Học viên ingest cả `sample-docs/` (một file chứa indirect injection — không được báo trước file nào), quan sát RAG pipeline có bị tác động không, phân tích vì sao retrieval kéo payload vào context. Sau đó hoàn thiện `security/promptfooconfig.yaml`, chạy `promptfoo redteam run`, đọc report, vá lỗ HIGH, chạy lại tới khi sạch.

### 10.2. Vì sao InsightHub là case study tốt cho bảo mật

- Là RAG app thật → có đủ LLM01 (indirect injection qua tài liệu), LLM02, LLM08.
- Có ChatOps bot (Day 5) → có LLM06 Excessive Agency thật để siết.
- `<context>` tách sẵn trong `llm.py` → học viên thấy prompt hardening là gì, và test xem nó chịu được tới đâu.

### 10.3. Bài học từ ngành — speed vs safety

Khảo sát: một SaaS lớn báo 30% IaC do AI sinh, nhưng gấp 3 lần config misfire. Lời junior dev: *"Tôi chỉ paste prompt, review thấy ổn, rồi push."* Day 6 dạy điều ngược lại — AI tăng tốc, nhưng governance (red-team + cost control + guardrails) đảm bảo tốc độ không biến thành nợ bảo mật.

### 10.4. Vì sao đây là buổi "đắt giá" nhất khóa

Phần lớn khóa học AI/DevOps dừng ở "làm được". Day 6 dạy "làm có trách nhiệm" — OWASP LLM + Agentic, defense-in-depth, FinOps. Đây là phần phân biệt một DevOps engineer *thực chiến* với người chỉ biết gọi API.

---

## 11. Thuật ngữ & Đọc thêm

### Thuật ngữ

- **OWASP LLM Top 10** — khung rủi ro cho ứng dụng LLM.
- **OWASP ASI Top 10** — khung rủi ro cho ứng dụng agentic (2026).
- **Prompt Injection** — input độc làm đổi hành vi LLM (LLM01).
- **Direct / Indirect injection** — payload qua input trực tiếp / qua nội dung ngoài.
- **System Prompt Leakage** — lộ system prompt (LLM07).
- **RAG poisoning** — đầu độc vector store / retrieval.
- **Excessive Agency** — agent có quá nhiều quyền (LLM06).
- **Defense in Depth** — phòng vệ nhiều lớp.
- **Guardrails** — lớp lọc input/output (Bedrock/NeMo/Llama Guard).
- **LLM FinOps** — quản trị chi phí LLM.
- **LLM Gateway** — tầng trung gian app ↔ provider (LiteLLM, Bifrost...).
- **Model routing** — chọn model theo độ phức tạp request.
- **Semantic caching** — cache theo độ tương tự ngữ nghĩa.

### Đọc thêm (khuyến nghị trước buổi)

- OWASP — Top 10 for LLM Applications 2025 (genai.owasp.org).
- OWASP — Top 10 for Agentic Applications 2026 (ASI).
- Promptfoo docs — red-team / OWASP LLM Top 10.

### Tự kiểm tra trước khi đến lớp

1. Vì sao bảo mật LLM khác bảo mật web truyền thống?
2. Vì sao không thể coi prompt injection như SQL injection?
3. LLM07 và LLM08 mới năm 2025 — vì sao được thêm?
4. Direct vs Indirect injection — cái nào nguy hiểm hơn với RAG, vì sao?
5. Vì sao agentic cần khung OWASP riêng?
6. 6 lớp của Defense in Depth là gì?
7. Token economics: tỷ lệ cost output:input thường là bao nhiêu? Hệ quả kiến trúc?
8. 4 trụ cột quản trị chi phí agent là gì?

---

*Pre-reading Day 6 — Module 7 AI-Native DevOps.*
