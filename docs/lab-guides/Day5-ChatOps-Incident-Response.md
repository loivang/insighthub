# Lab Guide — Day 5: ChatOps 2.0 + AI Incident Response

> **Module 7 — AI-Native DevOps** · Pillar B: Operate with AI
> Thời lượng: 2.5 giờ (150 phút) · Running project: **InsightHub**

---

## Mục tiêu buổi học

Kết thúc Day 5, học viên có thể:

1. Hiểu sự tiến hóa ChatOps: Hubot → Slack workflow → AI agent chat.
2. Build Slack bot AI-powered trả lời câu hỏi vận hành InsightHub qua MCP.
3. Áp dụng pattern human-in-the-loop: read-only mặc định, approval cho hành động nguy hiểm.
4. Triển khai audit trail cho mọi tool call của bot.

**Daily Artifact:** Slack bot live trả lời được ≥ 3 câu hỏi infra về InsightHub + audit log đầy đủ tool call.

---

## Chuẩn bị trước buổi

- [ ] Anomaly detection (Day 4) đã chạy
- [ ] Slack workspace cá nhân đã tạo
- [ ] ngrok đã cài
- [ ] Đã xem skeleton `chatops-bot/` trong repo

---

## Segment 1 — Recap & Hook (10 phút)

- Day 4 ta đã *observe* được InsightHub. Hôm nay: từ observe → **react**.
- Hook: "Observability tốt mà vẫn phải mở 5 tab dashboard lúc 2h sáng thì chưa đủ. ChatOps 2.0: hỏi bot 1 câu trong Slack, nó tự query cả cluster trả lời."
- Cảnh báo trước: "Bot biết `kubectl` thì cũng biết `kubectl delete`. Hôm nay học cả cách làm bot AN TOÀN."

---

## Segment 2 — Concept: ChatOps Evolution (30 phút)

### 2.1. Ba thế hệ ChatOps

| Thế hệ | Mô tả | Hạn chế |
|---|---|---|
| **Gen 1 — Hubot** | Bot chạy script cố định theo command | Cứng nhắc, phải nhớ command |
| **Gen 2 — Slack Workflow** | Workflow builder, tích hợp tool | Vẫn theo kịch bản định sẵn |
| **Gen 3 — AI agent chat** | Hỏi natural language, agent tự quyết tool nào | Mạnh — nhưng cần guardrails |

### 2.2. Kiến trúc ChatOps 2.0 cho InsightHub

```
Slack event → bot service (FastAPI) → Claude API + MCP (k8s, prometheus)
            → Claude tóm tắt → reply về Slack channel
                                  ↓
                            audit log mọi tool call
```

### 2.3. Knowledge graph cho DevOps

Bot mạnh hơn khi có context: runbook, postmortem, on-call doc. Nâng cao — hôm nay tập trung query real-time trước.

---

## Segment 3 — Best Practice: Bot an toàn (30 phút)

### 3.1. Human-in-the-loop

| Loại hành động | Chính sách |
|---|---|
| **Read** (get pods, query metrics, xem log) | Cho phép tự động |
| **Write** (scale, restart, apply) | Yêu cầu approval của người trong Slack |
| **Destructive** (delete, drain node) | Approval + confirmation token |

**Mặc định: read-only.** Bot chỉ làm được nhiều hơn khi có cơ chế approval rõ ràng.

### 3.2. Audit trail

Mọi tool call phải ghi audit: ai hỏi, tool gì, tham số gì, kết quả, có được approve không. Khi AI agent chạm hạ tầng, không có audit = không có trách nhiệm giải trình.

### 3.3. Bảo mật Slack

- Verify Slack signature mọi request (chống giả mạo).
- Cẩn thận DM vs channel — thông tin nhạy cảm không leak ra channel công khai.

---

## Segment 4 — Live Demo + Lab: Build ChatOps Bot (80 phút)

> Học viên hoàn thiện skeleton `chatops-bot/` đã có sẵn trong repo.

### Bước 1 — Tạo Slack App (15 phút)

1. Tạo Slack app tại api.slack.com, trỏ vào workspace cá nhân.
2. Bật Event Subscriptions, thêm bot event `app_mention`.
3. Lấy Signing Secret + Bot Token.
4. Cài bot vào workspace.

### Bước 2 — Chạy skeleton + ngrok (10 phút)

```bash
cd chatops-bot
pip install -r requirements.txt
uvicorn app.main:app --port 8100
# terminal khác:
ngrok http 8100
```

Trỏ Event Subscription URL của Slack vào `https://<ngrok>/slack/events`.
Slack gửi `url_verification` challenge — skeleton đã xử lý sẵn.

### Bước 3 — Hoàn thiện bot bằng Claude Code (40 phút)

Prompt:

```
Hoàn thiện chatops-bot/app/main.py và audit.py.
Yêu cầu:
- handle_question(): dùng Claude API với MCP servers (kubernetes, prometheus)
  để trả lời câu hỏi vận hành về InsightHub
- Verify Slack signature trong /slack/events (dùng SLACK_SIGNING_SECRET)
- Mặc định READ-ONLY: bot chỉ query, không thực hiện hành động ghi
- Mọi tool call gọi log_tool_call() để ghi audit
- audit.py: ghi audit dạng structured JSON, mỗi dòng 1 record
Bot phải trả lời được 3 câu:
  1. "InsightHub có healthy không?"
  2. "Hôm nay ingest bao nhiêu tài liệu?"
  3. "Pod nào của InsightHub đang lỗi?"
Trình bày plan trước khi sửa.
```

### Bước 4 — Test bot (15 phút)

Trong Slack, mention bot với 3 câu hỏi mẫu. Verify:
- Bot trả lời đúng, có dữ liệu thật từ cluster.
- Audit log ghi đủ tool call.
- Thử hỏi 1 hành động ghi ("restart pod api") → bot phải từ chối hoặc xin approval.

---

## Segment 5 — Workshop (10 phút)

Học viên deploy bot lên cluster (hoặc giữ chạy local + ngrok cho demo), test lại với prompt thật. Q&A.

---

## Daily Artifact — Checklist nộp

| # | Artifact | Cách verify |
|---|---|---|
| 1 | Slack bot live | Bot phản hồi trong Slack workspace |
| 2 | Trả lời 3 câu hỏi infra | Demo trực tiếp 3 câu mẫu |
| 3 | MCP backend hoạt động | Bot dùng k8s/prometheus MCP query thật |
| 4 | Audit log | File/log có structured record mọi tool call |
| 5 | Read-only enforced | Hành động ghi bị từ chối / xin approval |

---

## Troubleshooting

| Triệu chứng | Nguyên nhân | Xử lý |
|---|---|---|
| Slack không verify được URL | Endpoint chưa trả `challenge` | Skeleton đã xử lý — kiểm tra ngrok còn sống |
| Bot không nhận mention | Chưa subscribe event `app_mention` | Kiểm tra Event Subscriptions |
| Signature verify fail | Sai Signing Secret | Đối chiếu secret từ Slack app settings |
| Bot trả lời chung chung | Không gọi được MCP | Kiểm tra MCP server kết nối, API key |
| Audit log trống | Quên gọi `log_tool_call` | Mỗi tool call phải gọi audit |
| ngrok URL đổi sau restart | ngrok free đổi URL mỗi lần | Cập nhật lại URL trong Slack, hoặc dùng domain cố định |

---

## Homework (chuẩn bị Day 6)

1. Hoàn thiện bot nếu chưa xong.
2. Cài Promptfoo: `npm install -g promptfoo`.
3. Đọc OWASP LLM Top 10 (2025) + OWASP Agentic AI Top 10.
4. Chuẩn bị 1 file tài liệu "sạch" để test RAG.

---

## Ghi chú cho Trainer

- Skeleton `chatops-bot/app/{main,audit}.py` đã có sẵn trong repo với TODO rõ ràng — học viên không build from scratch.
- Slack app setup hay vướng nhất ở Event Subscription + ngrok. Để sẵn screencast bước này.
- Nhấn mạnh read-only: đây là cầu nối sang Day 6 (security). Bot có quyền = phải có guardrails.
- Nếu lớp yếu: Bước 3 có thể rút gọn — chỉ cần trả lời 1-2 câu hỏi, audit log cơ bản.
- Đáp án bot hoàn chỉnh: build và thêm vào `docs/reference-solutions/` trước buổi học.
