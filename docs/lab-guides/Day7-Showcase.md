# Lab Guide — Day 7: Showcase — InsightHub Production Demo

> **Module 7 — AI-Native DevOps** · Showcase
> Thời lượng: 2.5 giờ (150 phút) · Running project: **InsightHub**

---

## Mục tiêu buổi học

Day 7 KHÔNG dạy nội dung mới. Đây là buổi tổng kết:

1. Trình diễn InsightHub đã tiến hóa thành deployment production-grade.
2. Peer review chéo giữa 15 học viên.
3. Tổng kết 3 pillars + roadmap nâng cao.

**Final Artifact:** InsightHub deployment hoàn chỉnh với đủ 6 artifact (Day 1-6) + screencast 3 phút.

---

## Format Day 7 — giải bài toán 15 học viên

Lớp 15 người, không thể demo hết trong 2.5h. Nguyên tắc: **"Showcase, not Defense"** — điểm số đến từ artifact verify được (chấm async), demo chỉ là trình diễn.

| Block | Thời lượng | Hoạt động |
|---|---|---|
| Async grading | (trước Day 7) | Trainer chấm rubric qua repo/pipeline/dashboard URL/report — không cần xem demo |
| Volunteer Demo | 72 phút | 5-6 bạn volunteer demo 12 phút/bạn |
| Gallery Walk | 40 phút | 15 deployment live trên màn hình, peer review + voting |
| Wrap-up + Recognition + Roadmap | 38 phút | Tổng kết, vinh danh, định hướng |

---

## Chuẩn bị trước buổi

### Học viên (tất cả 15)

- [ ] InsightHub deployment hoàn chỉnh, đủ 6 artifact
- [ ] Screencast 3 phút (Loom) đã nộp — bắt buộc với cả 15 bạn
- [ ] Self-checklist 6 artifact đã rà
- [ ] Cost report 1 tuần đã tổng hợp

### Học viên volunteer (5-6 bạn)

- [ ] Slide demo ngắn + kịch bản demo 12 phút
- [ ] InsightHub đang live, sẵn sàng demo trực tiếp

### Trainer

- [ ] Đã chấm async 15 học viên theo Project Rubric
- [ ] Màn hình/setup cho gallery walk
- [ ] Phiếu voting cho peer review

---

## Final Project State — InsightHub phải có đủ

| # | Artifact | Từ buổi |
|---|---|---|
| 1 | Code refactor + 1 feature, AI-augmented, có `CLAUDE.md` | Day 1 |
| 2 | Terraform module pass checkov | Day 3 |
| 3 | CI/CD pipeline green | Day 3 |
| 4 | Observability + anomaly alert + AI RCA | Day 4 |
| 5 | ChatOps bot hoạt động + audit log | Day 5 |
| 6 | Promptfoo OWASP scan no-HIGH + threat model | Day 6 |
| 7 | Cost report < $5/tuần | Day 6 |

---

## Block 1 — Volunteer Demo (72 phút)

5-6 bạn volunteer, mỗi bạn **12 phút hard-cap** (10 phút demo + 2 phút Q&A).

Mỗi demo phải show:

1. **AI prompt log** — chứng minh AI-augmented, không phải làm tay.
2. **Pipeline green** — CI/CD chạy thành công.
3. **Anomaly dashboard** — Grafana với anomaly detection.
4. **ChatOps bot live** — hỏi bot 1 câu, bot trả lời thật.
5. **Security report** — Promptfoo no-HIGH.
6. **Cost report** — token cost 1 tuần.

Trainer + lớp đặt câu hỏi. **Lưu ý:** câu hỏi nên kiểm tra hiểu biết — "vì sao bạn chọn cách này", "đoạn code này làm gì" — để phát hiện vibe-coding không hiểu bản chất.

---

## Block 2 — Gallery Walk (40 phút)

Cả 15 deployment InsightHub hiển thị song song (mỗi bạn 1 màn hình/tab hoặc URL).

- Học viên đi vòng xem deployment của nhau (20 phút).
- Mỗi người vote theo các hạng mục (20 phút):
  - Best Architecture
  - Best Observability
  - Best Security
  - Best Cost Optimization
  - Most Creative Feature

Cách này đảm bảo cả 15 bạn đều được "trình bày" công sức, không chỉ 5-6 người demo.

---

## Block 3 — Wrap-up + Recognition + Roadmap (38 phút)

### 3.1. Recap 3 Pillars (10 phút)

| Pillar | Đã học gì | Mindset shift |
|---|---|---|
| A. Develop with AI | Coding agents, MCP, AI IaC/pipeline | API call → orchestrate agent |
| B. Operate with AI | AIOps, anomaly detection, ChatOps | Dashboard manual → AI RCA |
| C. Govern AI | OWASP, guardrails, FinOps | "Security là việc người khác" → built-in |

### 3.2. Recognition (8 phút)

Vinh danh theo các hạng mục voting. Nhiều hạng mục → nhiều học viên được ghi nhận, không chỉ top 3.

### 3.3. Roadmap nâng cao (15 phút)

Hướng đi tiếp cho học viên muốn dấn sâu:

- **AI Coding nâng cao:** Devin, Codex Cloud, async agents, build MCP server tự code.
- **Agentic security:** Agentic SAST, A2A protocol (agent-to-agent).
- **Platform Engineering:** Internal Developer Platform, Backstage.
- **MLOps thật:** nếu muốn rẽ sang ML — Kubeflow, MLflow, model serving.
- **Career path:** DevOps Engineer → Platform Engineer → AI Engineer.

### 3.4. Feedback survey (5 phút)

Học viên điền survey. Trainer thu thập để cải tiến khóa sau.

---

## Final Artifact — Checklist nộp

| # | Artifact | Cách verify |
|---|---|---|
| 1 | InsightHub deployment đủ 6 artifact | Trainer chấm async theo Project Rubric |
| 2 | Screencast 3 phút | Link Loom — bắt buộc cả 15 bạn |
| 3 | Cost report 1 tuần | File report |
| 4 | (Volunteer) Demo trực tiếp | Trong Block 1 |

**Pass:** Project Rubric ≥ 70%.

---

## Ghi chú cho Trainer

- **Async grading là chìa khóa** — chấm xong 15 học viên TRƯỚC Day 7. Demo không phải là cơ sở chấm điểm, chỉ là trình diễn. Điều này giải tỏa áp lực cho học viên yếu và giải bài toán không demo hết được.
- Gallery walk đảm bảo cả 15 bạn được ghi nhận — quan trọng cho tinh thần lớp.
- Khi Q&A volunteer demo: hỏi để kiểm tra hiểu biết, phát hiện vibe-coding (Risk R8). Học viên không giải thích được code của mình → phản ánh vào điểm Dimension 1 của rubric.
- Recognition nhiều hạng mục — tránh chỉ tôn vinh 3 người, 12 người còn lại hụt hẫng.
- Nếu có học viên chưa đạt: trao đổi riêng, cho phép nộp bù theo chính sách (xem Risk R7 — nộp bù 24-48h, hoặc 5/7 artifact = đủ điều kiện).
- Sau khóa: nhắc học viên **tear down infra** (RDS, EKS, ElastiCache) để tránh phát sinh cost.

---

## Lời kết cho học viên

Sau 7 ngày, InsightHub của bạn đã đi từ một app chạy local đơn giản tới một
deployment production-grade: observable, secure, cost-optimized — và mọi bước
đều có sự tham gia của AI agent. Đó chính là công việc của một DevOps Engineer
trong năm 2026: không phải người gõ ít lệnh hơn, mà là người **chỉ huy AI agent**
kết hợp với phán đoán kỹ thuật của chính mình.
