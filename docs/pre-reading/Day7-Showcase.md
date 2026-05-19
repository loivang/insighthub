# Pre-Reading — Day 7: Showcase — Chuẩn bị & Tổng kết

> **Module 7 — AI-Native DevOps** · Showcase
> Tài liệu đọc trước buổi học. Thời gian đọc ước tính: 15-20 phút.
> Lưu ý: Day 7 KHÔNG có lý thuyết mới. Tài liệu này giúp bạn chuẩn bị demo và
> nhìn lại toàn bộ hành trình 7 ngày.

---

## Mục lục

1. [Day 7 là gì](#1-day-7-là-gì)
2. [Final Project — InsightHub phải có đủ gì](#2-final-project)
3. [Chuẩn bị Showcase](#3-chuẩn-bị-showcase)
4. [Tổng kết 3 Pillars](#4-tổng-kết-3-pillars)
5. [Self-Checklist trước buổi](#5-self-checklist)
6. [Roadmap nâng cao sau khóa](#6-roadmap)

---

## 1. Day 7 là gì

Day 7 là buổi **tổng kết và trình diễn**, không dạy nội dung mới. Mục tiêu:

1. Trình diễn InsightHub đã tiến hóa thành deployment **production-grade**.
2. Peer review chéo — học hỏi cách làm của nhau.
3. Tổng kết 3 pillars và định hướng phát triển tiếp.

### 1.1. Triết lý: "Showcase, not Defense"

Đây không phải buổi "bảo vệ đồ án" căng thẳng. Điểm số đến từ **artifact verify được** (trainer chấm async qua repo/pipeline/dashboard/report TRƯỚC buổi học). Demo chỉ là *trình diễn* công sức — không phải cơ sở chấm điểm.

Nghĩa là: nếu bạn đã hoàn thành đủ artifact qua 6 ngày, bạn **đã đạt** trước khi Day 7 bắt đầu. Day 7 là ăn mừng, không phải thi.

### 1.2. Format buổi học

| Block | Thời lượng | Hoạt động |
|---|---|---|
| Volunteer Demo | 72 phút | 5-6 bạn volunteer demo 12 phút/bạn |
| Gallery Walk | 40 phút | 15 deployment hiển thị song song, peer review + voting |
| Wrap-up + Recognition + Roadmap | 38 phút | Tổng kết, vinh danh, định hướng |

Lớp 15 người không thể demo hết — nên dùng Gallery Walk để **cả 15 bạn** đều được trình bày, không chỉ người volunteer.

---

## 2. Final Project — InsightHub phải có đủ gì

Qua 6 ngày, InsightHub của bạn phải tích lũy đủ **7 artifact**:

| # | Artifact | Từ buổi | Verify thế nào |
|---|---|---|---|
| 1 | Code refactor + 1 feature, AI-augmented, có `CLAUDE.md` | Day 1 | Repo có `ingestion-worker` tách riêng, `CLAUDE.md` hoàn chỉnh, 1 PR |
| 2 | `.mcp.json` cấu hình 4+ MCP server | Day 2 | `claude mcp list` tất cả Connected |
| 3 | Terraform module pass checkov (no HIGH) | Day 3 | `checkov -d infra/` sạch |
| 4 | CI/CD pipeline green | Day 3 | Workflow run thành công trên GitHub |
| 5 | Observability + anomaly alert + AI RCA | Day 4 | Grafana dashboard RED, anomaly rule, 1 RCA report |
| 6 | ChatOps bot + audit log | Day 5 | Bot trả lời được câu hỏi infra, audit log đầy đủ |
| 7 | Promptfoo OWASP scan no-HIGH + threat model + cost report | Day 6 | Scan report sạch, threat model, cost dashboard |

### 2.1. Hành trình tiến hóa của InsightHub

```
v0  (trước Day 1):  app chạy local, 3 service, ingest đồng bộ
 │
 ├─ Day 1:  refactor async — 5 service, Redis queue
 ├─ Day 2:  containerize đầy đủ, MCP integration
 ├─ Day 3:  Terraform + CI/CD, deploy lên K8s
 ├─ Day 4:  observable — Prometheus, Grafana, anomaly detection
 ├─ Day 5:  ChatOps bot vận hành
 ├─ Day 6:  secured — red-team sạch, cost-optimized
 │
v1  (Day 7):  deployment production-grade hoàn chỉnh
```

Từ một app local đơn giản → một deployment production-grade: observable, secure, cost-optimized — và **mọi bước đều có AI agent tham gia**.

---

## 3. Chuẩn bị Showcase

### 3.1. Tất cả 15 học viên cần chuẩn bị

- [ ] InsightHub deployment hoàn chỉnh, đủ 7 artifact.
- [ ] **Screencast 3 phút** (Loom) — nộp TRƯỚC Day 7. Bắt buộc với cả 15 bạn.
- [ ] Cost report 1 tuần đã tổng hợp.
- [ ] Tự rà self-checklist (mục 5 dưới).

### 3.2. Nếu bạn là volunteer demo (5-6 bạn)

- [ ] Slide demo ngắn + kịch bản demo **12 phút** (10 demo + 2 Q&A).
- [ ] InsightHub đang live, sẵn sàng demo trực tiếp.
- [ ] Demo phải show được 6 thứ:
  1. **AI prompt log** — chứng minh AI-augmented.
  2. **Pipeline green** — CI/CD chạy thành công.
  3. **Anomaly dashboard** — Grafana có anomaly detection.
  4. **ChatOps bot live** — hỏi bot 1 câu, trả lời thật.
  5. **Security report** — Promptfoo no-HIGH.
  6. **Cost report** — token cost 1 tuần.

### 3.3. Lưu ý về Q&A

Trong Q&A, trainer và lớp sẽ hỏi để **kiểm tra hiểu biết** — "vì sao bạn chọn cách này", "đoạn code này làm gì". Đây không phải bẫy — mục đích là phân biệt người *hiểu* với người *vibe-code không hiểu*. Nếu bạn đã làm việc đúng cách với AI agent suốt 6 ngày (review, không approve mù), bạn sẽ trả lời được tự nhiên.

### 3.4. Gallery Walk — voting hạng mục

Cả 15 deployment hiển thị song song. Mỗi người vote:
- Best Architecture
- Best Observability
- Best Security
- Best Cost Optimization
- Most Creative Feature

Nhiều hạng mục → nhiều bạn được ghi nhận.

---

## 4. Tổng kết 3 Pillars

Nhìn lại toàn bộ khóa học qua lăng kính 3 trụ cột:

| Pillar | Buổi | Đã học | Mindset shift |
|---|---|---|---|
| **A. Develop with AI** | Day 1-3 | Coding agents, MCP, AI IaC/pipeline | Từ "gọi API" → "orchestrate agent" |
| **B. Operate with AI** | Day 4-5 | AIOps, anomaly detection, ChatOps | Từ "dashboard thủ công" → "AI RCA + hành động qua chat" |
| **C. Govern AI** | Day 6 | OWASP LLM/Agentic, guardrails, FinOps | Từ "bảo mật là việc người khác" → "built-in từ đầu" |

### 4.1. Sợi chỉ xuyên suốt

- **Running project** — InsightHub tiến hóa mỗi ngày, không học rời rạc.
- **AI-augmented** — mọi task đều có AI agent; bạn lưu prompt log để chứng minh.
- **Human judgment** — AI tăng tốc, nhưng phán đoán kỹ thuật và review vẫn là của bạn.
- **System thinking** — quyết định Day 1 (async) mở ra khả năng Day 4 (observe queue). Mọi thứ liên kết.

### 4.2. Định nghĩa lại vai trò DevOps Engineer 2026

> Công việc của DevOps Engineer 2026 không phải là người **gõ ít lệnh hơn** — mà là người **chỉ huy AI agent** kết hợp với phán đoán kỹ thuật của chính mình.

---

## 5. Self-Checklist trước buổi

Tự rà trước Day 7. Mỗi mục phải verify được:

```
[ ] Artifact 1 — ingestion-worker tách riêng, CLAUDE.md đầy đủ, 1 PR
[ ] Artifact 2 — .mcp.json 4+ server, claude mcp list OK
[ ] Artifact 3 — checkov -d infra/ no HIGH
[ ] Artifact 4 — CI/CD pipeline run green
[ ] Artifact 5 — Grafana dashboard + anomaly rule + 1 RCA report
[ ] Artifact 6 — ChatOps bot trả lời được câu hỏi infra + audit log
[ ] Artifact 7 — Promptfoo scan no-HIGH + threat model + cost dashboard
[ ] Screencast 3 phút đã quay và nộp
[ ] Cost report 1 tuần đã tổng hợp
[ ] InsightHub đang live, truy cập được
```

**Pass:** Project Rubric ≥ 70%. Nếu thiếu artifact nào, ưu tiên hoàn thiện trước Day 7 — hoặc trao đổi với trainer về chính sách nộp bù.

---

## 6. Roadmap nâng cao sau khóa

Hướng đi tiếp cho ai muốn dấn sâu:

### 6.1. AI Coding nâng cao
- Async agents (Devin, Codex Cloud) — giao task rồi đi làm việc khác.
- Tự code MCP server riêng cho tool nội bộ.
- Agent Teams / multi-agent orchestration.

### 6.2. Agentic Security
- OWASP ASI Top 10 sâu hơn — memory poisoning, rogue agents.
- Agentic SAST, A2A protocol security.

### 6.3. Platform Engineering
- Internal Developer Platform (IDP), Backstage.
- Self-service infrastructure với golden path.

### 6.4. MLOps thật (nếu muốn rẽ sang ML)
- Kubeflow, MLflow, model serving, feature store.
- Lưu ý: đây là track riêng — khóa này chỉ chạm "model as a service".

### 6.5. Career path
```
DevOps Engineer  →  Platform Engineer  →  AI Engineer / AI Reliability Engineer
```

Vai trò mới đang hình thành: **AI Reliability Engineering** — đảm bảo chất lượng, công bằng, minh bạch của hệ thống AI trong production.

---

## Lời kết

Sau 7 ngày, InsightHub của bạn đã đi từ một app chạy local đơn giản tới một
deployment production-grade. Quan trọng hơn cả artifact: bạn đã rèn được
**tư duy AI-Native** — biết khi nào giao việc cho AI, khi nào giữ phán đoán cho
mình, và làm thế nào để tốc độ của AI không biến thành nợ kỹ thuật hay nợ bảo mật.

Đó là năng lực mà thị trường 2026 đang trả giá cao nhất.

Hẹn gặp ở buổi Showcase.

---

*Pre-reading Day 7 — Module 7 AI-Native DevOps.*
