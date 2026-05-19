# Pre-Reading — Day 5: ChatOps 2.0 & AI Incident Response

> **Module 7 — AI-Native DevOps** · Pillar B: Operate with AI
> Tài liệu đọc trước buổi học. Thời gian đọc ước tính: 35-45 phút.
> Mục tiêu: hiểu lý thuyết ChatOps hiện đại và AI SRE agent để build bot an toàn.

---

## Mục lục

1. [Bối cảnh: bài toán on-call](#1-bối-cảnh)
2. [Concept: ChatOps & AI SRE Agent](#2-concept)
3. [Ba thế hệ ChatOps](#3-ba-thế-hệ)
4. [Core Components của một AI ChatOps bot](#4-core-components)
5. [Vòng đời incident response với AI](#5-vòng-đời)
6. [Human-in-the-Loop — nguyên tắc an toàn cốt lõi](#6-human-in-the-loop)
7. [Features & xu hướng 2026](#7-features)
8. [Implementation: kiến trúc bot](#8-implementation)
9. [Best Practices](#9-best-practices)
10. [Case Study](#10-case-study)
11. [Thuật ngữ & Đọc thêm](#11-thuật-ngữ)

---

## 1. Bối cảnh

### 1.1. Bài toán on-call

SRE vận hành theo mô hình **on-call** — kỹ sư trực 24/7, phản hồi mọi sự cố. Với microservice + multi-cloud + continuous deployment, bề mặt vận hành lớn tới mức con người không theo kịp.

Hệ quả: **alert fatigue**. Khảo sát PagerDuty: phần lớn incident responder nhận >10 alert/ca trực, và phần lớn nói các alert đó *không hành động được*. Escalation tree quá tải, kỹ sư bị kéo khỏi giấc ngủ / công việc sâu → burnout.

### 1.2. "Coordination tax" — 15 phút đầu tiên

Khi alert nổ lúc 3h sáng: kỹ sư phải mở nhiều tab, correlate telemetry từ nhiều nguồn, trace dependency, hình thành giả thuyết. Riêng việc *điều phối* (ai vào, ai biết gì) đã tốn ~15 phút trước khi chạm vào vấn đề thật.

### 1.3. Con số

- Tổ chức áp dụng AIOps báo cáo MTTR giảm **~40%**.
- Hệ thống AI incident management tốt giảm MTTR tới **80%** nhờ loại bỏ coordination overhead.
- ITIC 2024: >90% doanh nghiệp vừa và lớn báo downtime tốn **>$300,000/giờ**.

→ ChatOps 2.0 tấn công trực tiếp vào "coordination tax" và alert fatigue.

---

## 2. Concept

### 2.1. ChatOps là gì

> **ChatOps** là thực hành đưa việc vận hành (query hệ thống, chạy lệnh, quản lý incident) vào ngay nền tảng chat (Slack, Teams) — nơi team đã làm việc — thay vì bắt kỹ sư chuyển sang công cụ riêng.

### 2.2. AI SRE Agent — bước tiến của ChatOps

> Một **AI SRE Agent** là hệ thống phần mềm kết hợp dữ liệu observability + khả năng suy luận + khả năng thực thi hành động, để **tự chủ** quản lý các task reliability.

Từ khóa: **tự chủ (autonomous)**. Khác AI assistant thụ động (chỉ gợi ý khi được hỏi): AI SRE agent *quan sát môi trường liên tục*, suy luận, lập kế hoạch, thực thi task đa bước.

### 2.3. AI SRE Agent khác automation truyền thống thế nào

| | Automation truyền thống | AI SRE Agent |
|---|---|---|
| Kích hoạt | Chờ bạn trigger | Tự quan sát, tự phát hiện |
| Phạm vi | Script cố định | Suy luận theo ngữ cảnh |
| RCA | Không | Correlate telemetry + deploy + lịch sử incident |
| Ví dụ output | "latency cao" | "latency tăng ngay sau deploy sửa connection pool DB" |

---

## 3. Ba thế hệ ChatOps

| Thế hệ | Đại diện | Cách hoạt động | Hạn chế |
|---|---|---|---|
| **Gen 1 — Bot lệnh** | Hubot | Bot chạy script theo command regex cố định | Phải nhớ cú pháp; output là "wall of text" |
| **Gen 2 — Workflow** | Slack Workflow Builder | Workflow builder, tích hợp tool theo kịch bản | Vẫn theo kịch bản định sẵn |
| **Gen 3 — AI agent chat** | Rootly, incident.io, PagerDuty SRE Agent | Hỏi natural language, agent tự quyết tool, tự RCA, đề xuất fix | Mạnh — nhưng cần guardrails |

### 3.1. "Wall of text" — bệnh của ChatOps cũ

ChatOps text-only: hỏi status → nhận 50 dòng JSON không format, bảng vỡ trên mobile. Cú pháp lệnh phải nhớ ("scale service checkout –x=3" hay "service scale checkout 3"?). Đây là *last-mile failure* — agent thông minh nhưng output "ngu".

### 3.2. Hướng tương lai — A2UI (Agent-to-User Interface)

Google open-source A2UI: agent gửi một JSON blueprint mô tả ý định ("card có title, metric, 2 nút"), client tin cậy render bằng component native. Thay vì wall-of-text → **Incident Card** có SLO trực tiếp, sparkline latency, dropdown chọn region, nút "Scale 2x" / "Rollback" — mỗi nút gated bằng confirmation + RBAC. Đây là hướng nâng cao; Day 5 dùng bot text trước, A2UI là tương lai để biết.

---

## 4. Core Components của một AI ChatOps bot

```
Slack event  →  Bot service  →  AI agent (LLM + MCP)  →  reply về Slack
                    │                  │
                    │                  ├─ MCP: kubernetes, prometheus
                    │                  └─ LLM: Claude tóm tắt, suy luận
                    │
                    └─ Audit log (mọi tool call)
```

| Thành phần | Vai trò |
|---|---|
| **Chat platform integration** | Nhận event từ Slack/Teams, gửi reply. Verify signature. |
| **Bot service** | Backend (FastAPI...) nhận event, điều phối |
| **AI agent** | LLM + MCP backend — query hệ thống, suy luận, tóm tắt |
| **Service catalog / Knowledge** | Context: service ownership, dependency, runbook, deploy gần đây |
| **Audit log** | Ghi mọi tool call — ai hỏi, tool gì, kết quả, có approve không |
| **Permission / Approval layer** | Read-only mặc định; hành động ghi cần approval |

### 4.1. Service catalog — nền tảng bị bỏ quên

Trước khi AI agent giúp được, nó cần *biết* hạ tầng: service ownership, dependency, vị trí runbook, deploy gần đây. Xây service catalog là bước đầu tiên của mọi triển khai AI SRE thực tế. Không có catalog, agent chỉ "đoán mò".

---

## 5. Vòng đời incident response với AI

Mô hình trưởng thành 4 phase (tổng hợp từ thực tiễn ngành):

```
Phase 1: Detection      → AI phát hiện anomaly (Day 4)
Phase 2: Triage         → AI correlate, declare incident, tạo Slack channel,
                          mời đúng on-call, enrich alert với context
Phase 3: Human-in-loop  → AI đề xuất fix kèm bằng chứng → người approve qua Slack
                          → AI thực thi → monitor kết quả
Phase 4: Learning       → AI tự sinh postmortem summary; feed lesson về
                          tinh chỉnh threshold, retrain model, cập nhật runbook
```

### 5.1. Bốn năng lực của AI SRE Agent

1. **Autonomous alert triage** — correlate tín hiệu liên quan, suppress duplicate, enrich alert chính với context (code change, infra liên quan).
2. **Automated RCA** — pull data từ alert + telemetry + code change + incident quá khứ, chỉ ra nguyên nhân *kèm bằng chứng*.
3. **Remediation workflow** — rollback deploy, scale fleet, restart pod — *với human-in-the-loop cho hành động rủi ro cao*.
4. **Real-time summary** — tóm tắt cho người vào muộn (Slack `/catchup`), transcribe Slack huddle thành record tìm kiếm được.

---

## 6. Human-in-the-Loop — nguyên tắc an toàn cốt lõi

### 6.1. Vì sao bắt buộc

AI SRE agent có quyền thực thi (`kubectl`, rollback, scale). Quyền lực này phải đi kèm kiểm soát. Nguyên tắc nền của AI-native SRE: **hành động phải bounded, reversible, và cần human approval**.

### 6.2. Phân loại hành động

| Loại | Chính sách | Ví dụ |
|---|---|---|
| **Read** | Cho phép tự động | get pods, query metric, xem log |
| **Write** | Cần approval qua Slack | scale, restart pod, cập nhật config |
| **Destructive** | Approval + confirmation token | delete, drain node |

**Mặc định: read-only.** Bot chỉ làm nhiều hơn khi có cơ chế approval rõ ràng.

### 6.3. Pattern "AI recommends, humans approve, systems execute"

Dự báo 2026: tổ chức SRE áp dụng workflow hybrid — *AI đề xuất, người duyệt, hệ thống thực thi*, **mọi bước đều log và giải thích được**. Agent xác định vấn đề → đề xuất fix kèm bằng chứng → bạn approve qua Slack command → agent thực thi → agent monitor cải thiện.

### 6.4. Vai trò mới của SRE

Khi AIOps trưởng thành, SRE chuyển từ *executor* sang *incident strategist* — tập trung cải thiện hệ thống thay vì chữa cháy chiến thuật. Vai trò mới hơn nữa: **"AI reliability engineering"** — đảm bảo chất lượng, công bằng, minh bạch của hệ thống AI incident response; tune model behavior, validate remediation policy, thiết kế fallback cho edge case nơi phán đoán con người là không thể thay thế.

---

## 7. Features & xu hướng 2026

### 7.1. Landscape công cụ

| Công cụ | Đặc điểm |
|---|---|
| **Rootly** | AI SRE chạy trong Slack, `/rootly catchup`, transcribe huddle, correlate GitHub PR + observability |
| **incident.io** | AI SRE agent, autonomous triage, RCA, remediation với approval |
| **PagerDuty SRE Agent** | Triage + fix trước khi page; thêm agent vào escalation policy như "virtual responder"; MCP integration với Cursor/Claude Code |
| **AWS DevOps Agent** | Topology intelligence, three-tier skills, cross-account; "Agent Space" cấu hình 1 lần, mọi SRE dùng chung |
| **Onepane** | Agentic ITOps, deploy trong tenant khách — data không rời môi trường |

### 7.2. Xu hướng "operational teammate", không chỉ "LLM wrapper"

Nhiều team bắt đầu bằng cách dùng coding agent yêu thích làm "thin wrapper over LLM" cho điều tra. Nhưng AI SRE agent thực thụ hơn thế: topology intelligence, skills hierarchy, continuous learning, cross-account — "operational teammate" thật sự, không phải wrapper mỏng.

### 7.3. Zero-setup qua shared config

Vấn đề với MCP per-engineer: mỗi kỹ sư tự kết nối agent với MCP server (CloudWatch, observability, repo, ticketing). Thực tế: vài người làm đầy đủ, vài người làm dở, vài người không bao giờ → tooling không nhất quán. Giải pháp: cấu hình 1 lần (vd "Agent Space"), mọi người inherit. SRE mới vào on-call không tốn cả ngày wiring access.

### 7.4. Continuous learning

Hệ thống học từ kết quả incident trước (action hiệu quả hay thất bại) và thích nghi. Vd: nếu auto-restart pod liên tục giải quyết latency của một microservice, platform học cách auto-suggest (rồi dần auto-execute) fix đó với confidence cao hơn.

---

## 8. Implementation — kiến trúc bot

### 8.1. Luồng kỹ thuật cho InsightHub ChatOps bot

```
1. Slack event  →  POST /slack/events
2. Verify Slack signature           (chống giả mạo — bắt buộc)
3. Parse event, trích câu hỏi user
4. handle_question():
   - AI agent + MCP (kubernetes, prometheus) query InsightHub
   - Claude tóm tắt kết quả
   - GHI AUDIT LOG mọi tool call
   - Hành động ghi → xin approval
5. Reply về Slack channel
```

### 8.2. Bảo mật Slack — verify signature

Mọi request từ Slack phải verify chữ ký (dùng Signing Secret). Không verify = bất kỳ ai biết URL endpoint đều giả mạo được event. Đây là yêu cầu bảo mật cơ bản.

### 8.3. MCP backend — tái dùng từ Day 2

Bot dùng chính MCP server đã cấu hình Day 2 (kubernetes, prometheus). Không phát minh lại — agent chat và agent coding chia sẻ cùng tầng tool MCP.

### 8.4. Audit log — structured

Mỗi tool call ghi 1 record JSON: `{ts, user, tool, args, result, approved}`. Production: đẩy sang log aggregator (Loki). Khi AI agent chạm hạ tầng, không có audit = không có trách nhiệm giải trình.

---

## 9. Best Practices

### 9.1. Human-in-the-loop là mặc định, không phải tùy chọn

Read-only by default. Hành động ghi/destructive luôn qua approval. Confirmation token cho destructive.

### 9.2. Audit trail mọi thứ

Mọi tool call — kể cả read — nên log. Khi sự cố xảy ra, audit log là thứ duy nhất cho biết bot đã làm gì.

### 9.3. Bounded, reversible actions

Hành động bot thực thi phải có giới hạn (bounded) và đảo ngược được (reversible). Rollback được ưu tiên hơn "fix" không thể undo.

### 9.4. Slack DM vs channel

Thông tin nhạy cảm (secret, log chứa PII) không leak ra channel công khai. Cân nhắc DM cho nội dung nhạy cảm.

### 9.5. Đo lường trước khi rollout

Định nghĩa mục tiêu đo được trước: "giảm thời gian phản hồi 30%", "tăng độ chính xác first-response". Retrospective định kỳ để validate đóng góp của AI.

### 9.6. "Đừng tự build hệ thống incident Slack từ đầu" — nhưng học thì nên

Lời khuyên ngành: với production thật, dùng nền tảng có sẵn (incident.io, Rootly) thay vì tự build — họ có "sane defaults". NHƯNG để *học* cách nó hoạt động, tự build một bot tối giản (như Day 5) là cách tốt nhất hiểu bản chất.

### 9.7. Anti-patterns

| Anti-pattern | Hậu quả |
|---|---|
| Bot có quyền write mặc định | Một prompt sai → hành động phá hoại |
| Không verify Slack signature | Bất kỳ ai giả mạo được event |
| Không audit log | Không truy được bot đã làm gì |
| Wall-of-text output | Kỹ sư không đọc được lúc 3h sáng |
| Bot không có service catalog | Agent đoán mò, RCA kém |

---

## 10. Case Study

### 10.1. InsightHub ChatOps bot — bài Day 5

Học viên hoàn thiện skeleton `chatops-bot/`. Bot phải trả lời được 3 câu hỏi vận hành:
- "InsightHub có healthy không?"
- "Hôm nay ingest bao nhiêu tài liệu?"
- "Pod nào đang lỗi?"

Bot dùng MCP backend (kubernetes + prometheus từ Day 2), Claude tóm tắt, ghi audit log mọi tool call, read-only mặc định.

### 10.2. Vì sao bài này nối tiếp Day 4

Day 4 ta *observe* được InsightHub (metrics, anomaly). Day 5 biến observability đó thành *hành động qua hội thoại*: thay vì mở 5 tab Grafana lúc 2h sáng, hỏi bot 1 câu. Đây là minh họa vòng *Detection → Triage* của incident lifecycle.

### 10.3. Bài học từ ngành — "trust through transparency"

Lời một Ops Lead (FinTrust): *"Trước đây kỹ sư lọc dashboard/log hơn 30 phút trước khi hành động. Giờ alert correlated kèm context + đề xuất remediation đẩy thẳng vào Slack, cắt triage time 70%. Quan trọng hơn — team tự tin hành động nhanh hơn vì hệ thống đã chiếm được niềm tin của họ."*

Niềm tin đến từ **minh bạch**: bot dẫn bằng chứng, log mọi thứ, để con người quyết định cuối. Đó chính là thiết kế của InsightHub bot — read-only, audit đầy đủ, human approve hành động ghi.

---

## 11. Thuật ngữ & Đọc thêm

### Thuật ngữ

- **ChatOps** — đưa vận hành vào nền tảng chat.
- **AI SRE Agent** — agent tự chủ quản lý task reliability.
- **On-call** — mô hình trực sự cố 24/7.
- **Alert fatigue** — kiệt sức vì quá nhiều alert (nhiều cái vô nghĩa).
- **Coordination tax** — thời gian phí cho điều phối trước khi chạm vấn đề thật.
- **Human-in-the-Loop** — AI đề xuất, người duyệt, hệ thống thực thi.
- **Service catalog** — danh mục service: ownership, dependency, runbook.
- **A2UI** — Agent-to-User Interface, agent gửi UI blueprint thay wall-of-text.
- **Bounded / reversible action** — hành động có giới hạn, đảo ngược được.
- **MTTR** — Mean Time To Resolution.

### Đọc thêm (khuyến nghị trước buổi)

- incident.io blog — "What is an AI SRE agent".
- Rootly — "What Is an AI SRE Agent" (2026).

### Tự kiểm tra trước khi đến lớp

1. "Coordination tax" là gì? AI SRE agent giải nó thế nào?
2. Ba thế hệ ChatOps — Gen 3 khác Gen 1 ở đâu?
3. AI SRE agent khác automation truyền thống thế nào?
4. 3 loại hành động (read/write/destructive) — chính sách approval cho mỗi loại?
5. Vì sao phải verify Slack signature?
6. Vì sao audit log bắt buộc?
7. Vai trò SRE thay đổi thế nào khi AIOps trưởng thành?

---

*Pre-reading Day 5 — Module 7 AI-Native DevOps.*
