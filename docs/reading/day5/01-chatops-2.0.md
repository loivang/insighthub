# Day 5 — Tài liệu đọc trước · Topic 1
# ChatOps 2.0 — Vận hành qua đối thoại

> **Thời gian đọc:** ~22 phút

---

## 1. Lý thuyết cơ bản

### 1.1. ChatOps là gì

ChatOps = đưa các thao tác vận hành (operations) vào **kênh chat** (Slack, Teams).
Thay vì mỗi kỹ sư tự SSH vào server / mở dashboard riêng, công việc vận hành diễn
ra **công khai trong kênh chat** — ai cũng thấy, ai cũng học được, có dấu vết.

### 1.2. Vì sao ChatOps quan trọng

- **Shared context:** cả team thấy chuyện gì đang xảy ra, không phải chỉ người trực.
- **Audit tự nhiên:** mọi thao tác để lại lịch sử chat.
- **Onboarding:** người mới học bằng cách đọc lịch sử kênh.
- **ChatOps + AI:** kết hợp với AI agent, kênh chat thành giao diện vận hành
  bằng ngôn ngữ tự nhiên.

### 1.3. Từ "observe" tới "react"

Day 4 dạy *quan sát* hệ thống (observability). Nhưng quan sát xong vẫn phải
*hành động*. ChatOps 2.0 là cây cầu: từ dashboard tới hành động, qua đối thoại.

---

## 2. Concept & Core Components

### 2.1. Ba thế hệ ChatOps

| Thế hệ | Mô tả | Hạn chế |
|---|---|---|
| **Gen 1 — Hubot** | Bot chạy script cố định theo command đã định nghĩa | Cứng nhắc, phải nhớ chính xác command |
| **Gen 2 — Slack Workflow** | Workflow builder, nút bấm, tích hợp tool | Vẫn theo kịch bản dựng sẵn |
| **Gen 3 — AI agent chat** | Hỏi bằng ngôn ngữ tự nhiên, agent tự quyết tool nào | Mạnh — nhưng cần guardrails |

ChatOps 2.0 = Gen 3.

### 2.2. Kiến trúc một AI ChatOps bot

```
Người dùng @mention bot trong Slack
        │
        ▼
Slack gửi event → Bot service (vd FastAPI)
        │
        ├─ verify chữ ký Slack (bảo mật)
        ├─ trích câu hỏi
        ▼
Bot gọi Claude API + MCP servers (kubernetes, prometheus)
        │
        ├─ agent query cluster / metrics
        ├─ ghi AUDIT mọi tool call
        ▼
Claude tóm tắt → Bot trả lời về kênh Slack
```

### 2.3. Core components

| Component | Vai trò |
|---|---|
| **Slack App** | Đăng ký bot, nhận event, gửi tin nhắn |
| **Bot service** | Nhận event Slack, điều phối — vd FastAPI |
| **Claude API + MCP** | "Bộ não" — hiểu câu hỏi, gọi tool, tóm tắt |
| **Audit log** | Ghi mọi tool call — không thể thiếu |
| **ngrok / public URL** | Cho Slack gọi tới bot service khi dev local |

---

## 3. Features — bot ChatOps làm được gì

### 3.1. Trả lời câu hỏi vận hành

InsightHub ChatOps bot cần trả lời được:

- *"InsightHub có healthy không?"* → kiểm tra pod, trả lời tổng quan.
- *"Hôm nay ingest bao nhiêu tài liệu?"* → query metric/DB.
- *"Pod nào đang lỗi?"* → liệt kê pod không Running.

### 3.2. Slack event flow

Khi cấu hình Slack App, có một bước **URL verification**: Slack gửi một
`challenge` tới endpoint của bot, bot phải trả lại đúng `challenge` để Slack xác
nhận URL hợp lệ. Sau đó Slack mới gửi các event thật (như `app_mention`).

### 3.3. Knowledge graph cho ChatOps (nâng cao)

Bot mạnh hơn nhiều khi có thêm context tĩnh: runbook, postmortem, tài liệu
on-call. Khi đó bot không chỉ trả lời "pod X đang lỗi" mà còn "theo runbook,
sự cố này thường do Y, thử Z". Nâng cao — không bắt buộc trong khóa này.

---

## 4. Implementation — xây ChatOps bot cho InsightHub

### 4.1. Repo đã có skeleton

InsightHub có sẵn `chatops-bot/` với khung code và các điểm TODO rõ ràng. Học
viên **hoàn thiện** skeleton, không xây từ đầu. Hai file chính:

- `app/main.py` — endpoint `/slack/events`, hàm `handle_question()`.
- `app/audit.py` — ghi audit log.

### 4.2. Các bước triển khai

```
1. Tạo Slack App, bật Event Subscriptions, lấy Signing Secret + Bot Token
2. Chạy bot service local + ngrok → có public URL
3. Trỏ Event Subscription URL của Slack vào https://<ngrok>/slack/events
4. Hoàn thiện handle_question(): dùng Claude API + MCP query InsightHub
5. Hoàn thiện audit.py: ghi structured log mọi tool call
6. Test: @mention bot 3 câu hỏi mẫu
```

### 4.3. Kết nối với MCP

Bot dùng chính các MCP server đã cấu hình từ Day 2 (kubernetes, prometheus) làm
"tay chân" để query cluster và metrics. Đây là lý do Day 2 quan trọng — MCP là
nền tảng cho cả Day 4 (RCA) và Day 5 (ChatOps).

---

## 5. Best Practices

1. **Verify chữ ký Slack** mọi request — chống giả mạo event.
2. **Xử lý `url_verification`** — bước bắt buộc khi setup Slack App.
3. **Bot trả lời ngắn gọn** — kênh chat không phải nơi đổ log thô.
4. **Ghi audit mọi tool call** — chi tiết ở Topic 2.
5. **Mặc định read-only** — chi tiết ở Topic 2.
6. **Tách DM vs channel** — thông tin nhạy cảm không đổ ra kênh công khai.
7. **Bot có lỗi thì báo rõ** — đừng im lặng khi MCP/API fail.

### Anti-patterns

| Anti-pattern | Hậu quả |
|---|---|
| Không verify chữ ký Slack | Kẻ xấu giả event điều khiển bot |
| Bot đổ log thô vào kênh | Kênh nhiễu, khó đọc |
| Bot trả lời thông tin nhạy cảm ra channel công khai | Rò rỉ thông tin |
| Bot im lặng khi lỗi | Người dùng không biết chuyện gì xảy ra |

---

## 6. Case Study — Sự cố lúc 2h sáng: dashboard vs ChatOps

**Bối cảnh:** 2h sáng, alert nổ — InsightHub có vấn đề. Kỹ sư on-call bị đánh thức.

### Không có ChatOps bot

Kỹ sư mở laptop, VPN vào, mở Grafana (tab 1), mở `kubectl` (terminal), mở log
aggregator (tab 2), mở runbook (tab 3). Vừa buồn ngủ vừa ghép nối thông tin từ
4 nguồn. Mất 15-20 phút chỉ để *hiểu chuyện gì đang xảy ra*.

### Có ChatOps bot

Kỹ sư mở Slack ngay trên điện thoại:

```
@insighthub-bot InsightHub có healthy không? Pod nào lỗi?
```

Bot (qua MCP) kiểm tra cluster, trả lời trong kênh:

> InsightHub: 4/5 service Running. `ingestion-worker` đang CrashLoopBackOff
> (restart 7 lần). Log gần nhất: "redis connection refused". Có vẻ Redis không
> truy cập được.

Trong 30 giây, kỹ sư đã có bức tranh tổng quan — ngay trên điện thoại, chưa cần
mở laptop. Và vì trả lời nằm **trong kênh Slack**, cả team sáng hôm sau đọc
được, không cần kể lại.

**Bài học:** ChatOps 2.0 không chỉ "tiện" — nó **rút ngắn thời gian từ alert tới
hiểu vấn đề**, và biến mọi thao tác xử lý sự cố thành kiến thức chung của team.
Nhưng — như Topic 2 sẽ nói — một bot trả lời được câu hỏi cũng là một bot *có
quyền chạm hạ tầng*, nên phải xây cho an toàn.

---

## Tự kiểm tra trước buổi học

1. ChatOps khác việc mỗi kỹ sư tự SSH vào server ở điểm nào?
2. Ba thế hệ ChatOps — ChatOps 2.0 là thế hệ nào?
3. Mô tả luồng từ "@mention bot" tới "bot trả lời".
4. `url_verification` của Slack là bước gì?
5. Vì sao bot dùng lại MCP server từ Day 2?

---

## Đọc thêm (tùy chọn)

- Slack API docs — Events API
- Atlassian — ChatOps guide
