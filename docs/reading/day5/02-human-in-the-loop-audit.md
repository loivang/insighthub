# Day 5 — Tài liệu đọc trước · Topic 2
# Human-in-the-Loop & Audit cho AI Agent

> **Thời gian đọc:** ~18 phút

---

## 1. Lý thuyết cơ bản

### 1.1. Khi bot có quyền hành động

Một ChatOps bot trả lời được *"pod nào đang lỗi?"* nghĩa là nó có quyền **đọc**
trạng thái cluster. Chỉ cần thêm một bước, nó có thể **restart pod**, **scale
deployment**, thậm chí **xóa** resource.

> Bot biết `kubectl get` thì cũng dễ dàng biết `kubectl delete`.

Câu hỏi cốt lõi của Topic 2: **làm sao để bot hữu ích mà không nguy hiểm?**

### 1.2. Hai rủi ro

- **Bot hiểu sai:** người dùng nói "dọn pod cũ ở staging", bot hiểu nhầm phạm vi,
  xóa nhầm.
- **Bot bị lợi dụng:** ai đó (hoặc một prompt injection — Day 6) khiến bot làm
  việc có hại.

Cả hai đều dẫn tới: **AI agent có quyền = AI agent có thể gây hại**. Giải pháp
không phải "bỏ quyền" (bot sẽ vô dụng), mà là **kiểm soát quyền**.

---

## 2. Concept & Core Components

### 2.1. Human-in-the-Loop (HITL)

HITL = giữ con người trong vòng quyết định cho các hành động quan trọng. Bot
không tự ý làm việc rủi ro — nó **đề xuất**, con người **phê duyệt**.

### 2.2. Phân loại hành động theo rủi ro

| Loại | Ví dụ | Chính sách |
|---|---|---|
| **Read** | get pods, query metric, xem log | Cho phép tự động |
| **Write** | scale, restart, apply config | Yêu cầu approval của người trong Slack |
| **Destructive** | delete pod/resource, drain node | Approval + confirmation token |

**Nguyên tắc nền: mặc định read-only.** Bot bắt đầu với quyền tối thiểu (chỉ
đọc). Chỉ mở rộng khi có cơ chế approval rõ ràng.

### 2.3. Audit Trail

Audit trail = bản ghi **mọi** hành động của bot: ai yêu cầu, tool gì, tham số gì,
kết quả ra sao, có được approve không.

> Khi AI agent chạm vào hạ tầng mà không có audit, thì không có **trách nhiệm
> giải trình** (accountability). Có chuyện xảy ra — không ai biết bot đã làm gì,
> vì sao, theo lệnh ai.

---

## 3. Core Components — cơ chế cụ thể

### 3.1. Read-only by default

Bot khởi đầu chỉ có tool đọc. Đây cũng là lý do Day 2 cấu hình MCP server với
`--read-only` và credential read-only — quyền bị giới hạn ngay từ tầng hạ tầng.

### 3.2. Approval gate

Với hành động Write/Destructive, bot không thực thi ngay. Thay vào đó:

1. Bot **đề xuất** hành động trong kênh: "Tôi định restart pod `api`. Xác nhận?"
2. Một người **có thẩm quyền** phản hồi xác nhận.
3. Bot mới thực thi.

### 3.3. Confirmation token

Với hành động destructive, thêm một lớp: bot yêu cầu nhập một **token xác nhận**
(vd một chuỗi ngẫu nhiên bot sinh ra). Tránh "lỡ tay gõ yes". Người dùng phải
chủ động copy token → thể hiện sự cố ý.

### 3.4. Audit log — ghi gì

Mỗi tool call ghi một record có cấu trúc (structured JSON), tối thiểu:

| Trường | Ý nghĩa |
|---|---|
| `timestamp` | Khi nào |
| `user` | Ai yêu cầu (Slack user ID) |
| `tool` | Tool nào được gọi |
| `args` | Tham số |
| `result` | Kết quả tóm tắt |
| `approved` | Có qua approval không |

Trong production thật: đẩy audit log sang log aggregator (Loki...) để tìm kiếm,
giữ lâu dài, không sửa được.

### 3.5. Verify chữ ký Slack

Mọi event Slack gửi tới bot kèm một chữ ký (dựa trên Signing Secret). Bot **phải
verify** chữ ký này — nếu không, kẻ xấu có thể giả một event Slack để điều khiển
bot. Đây là tuyến phòng thủ đầu tiên, trước cả HITL.

---

## 4. Implementation — bot an toàn cho InsightHub

### 4.1. Kiến trúc phòng vệ nhiều lớp

```
Lớp 1: Verify chữ ký Slack    → chỉ event Slack thật mới được xử lý
Lớp 2: Read-only mặc định     → bot chỉ query, không hành động ghi
Lớp 3: Approval gate          → hành động Write cần người duyệt
Lớp 4: Confirmation token     → hành động Destructive cần token
Lớp 5: Audit log              → mọi tool call để lại dấu vết
Lớp 6: MCP least-privilege    → credential read-only từ tầng hạ tầng (Day 2)
```

Lưu ý: lớp 6 (least-privilege ở tầng MCP/RBAC) là **lưới an toàn cuối cùng** —
kể cả khi lớp 1-5 bị vượt qua, RBAC vẫn chặn hành động ghi.

### 4.2. Trong khóa học

InsightHub ChatOps bot ở Day 5 được xây **read-only** — trả lời câu hỏi vận hành,
không thực hiện hành động ghi. Khung `audit.py` đã có sẵn, học viên hoàn thiện để
ghi đủ mọi tool call. Đây là nền tảng; cơ chế approval cho hành động ghi là
hướng mở rộng.

---

## 5. Best Practices

1. **Mặc định read-only** — quyền tối thiểu, mở rộng có kiểm soát.
2. **Verify chữ ký Slack** — tuyến phòng thủ đầu tiên.
3. **Approval gate cho Write, confirmation token cho Destructive.**
4. **Audit MỌI tool call** — không có ngoại lệ.
5. **Audit log bất biến** — đẩy sang nơi không sửa được.
6. **Người duyệt phải có thẩm quyền** — không phải ai trong kênh cũng approve được.
7. **Phòng vệ nhiều lớp** — không dựa vào một cơ chế duy nhất.

### Anti-patterns

| Anti-pattern | Hậu quả |
|---|---|
| Bot có quyền ghi không cần approval | Một câu lệnh sai → sự cố production |
| Không verify chữ ký Slack | Bot bị điều khiển bằng event giả |
| Audit chỉ ghi hành động ghi, bỏ hành động đọc | Sót dấu vết, khó điều tra |
| Audit log ghi ra nơi sửa được | Dấu vết có thể bị xóa/sửa |
| Tin rằng "bot của mình thì an toàn" | Bỏ qua rủi ro prompt injection (Day 6) |

---

## 6. Case Study — Một dòng lệnh và tầm quan trọng của approval gate

**Bối cảnh:** một team triển khai ChatOps bot có quyền **ghi** — bot có thể
`kubectl delete pod` trực tiếp, không qua approval. "Để tiện xử lý sự cố nhanh."

Một ngày, một kỹ sư muốn dọn các pod ở trạng thái `Evicted` trong namespace
`staging`. Anh ấy gõ:

```
@bot xóa hết pod evicted
```

Anh ấy *quên* nói namespace. Bot — không có context namespace cụ thể — diễn giải
"hết pod evicted" trên **toàn cluster**, bao gồm cả namespace `production`. Bot
có quyền ghi, không có approval gate → thực thi ngay. Một số pod production bị
xóa nhầm.

### Nếu có approval gate

Bot sẽ không thực thi ngay. Nó **đề xuất**:

> Tôi định xóa 12 pod ở trạng thái Evicted: 3 pod ở `staging`, **9 pod ở
> `production`**. Xác nhận? (token: `a7f3k9`)

Kỹ sư đọc, lập tức thấy "9 pod ở production" — sai ý định. Anh ấy không xác nhận,
sửa lại câu lệnh nói rõ namespace. Sự cố không xảy ra.

**Bài học:** approval gate không chỉ chống kẻ xấu — nó chống chính **lỗi vô ý**
của người dùng hợp lệ. Khoảnh khắc bot *hiển thị* nó sắp làm gì, trước khi làm,
là khoảnh khắc con người kịp nhận ra sai sót. Đây là bản chất của human-in-the-
loop, và là cầu nối trực tiếp sang Day 6: khi quyền lực tăng, cơ chế kiểm soát
phải tăng theo.

---

## Tự kiểm tra trước buổi học

1. Vì sao giải pháp không phải là "bỏ quyền của bot"?
2. Phân loại Read / Write / Destructive — chính sách mỗi loại?
3. "Mặc định read-only" nghĩa là gì?
4. Audit log nên ghi những trường nào?
5. Approval gate chống được cả rủi ro nào ngoài "kẻ xấu"?

---

## Đọc thêm (tùy chọn)

- Slack API — verifying requests with signing secrets
- OWASP — Agentic AI security (chuẩn bị cho Day 6)
