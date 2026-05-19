# Day 6 — Tài liệu đọc trước · Topic 2
# FinOps cho LLM — Quản trị chi phí AI

> **Thời gian đọc:** ~16 phút

---

## 1. Lý thuyết cơ bản

### 1.1. FinOps là gì

**FinOps** (Financial Operations) = thực hành quản trị chi phí cloud một cách
chủ động: ai cũng thấy được chi phí, tối ưu liên tục, ra quyết định dựa trên dữ
liệu cost. Với hạ tầng cloud truyền thống đã quen thuộc. Với **LLM workload**,
FinOps có những đặc thù riêng.

### 1.2. Vì sao LLM cần FinOps riêng

- **Chi phí theo token, không theo giờ.** Server tính theo giờ chạy — dự đoán
  được. LLM tính theo token — phụ thuộc vào lượng dùng, khó dự đoán hơn.
- **Đắt hơn nhiều.** Một LLM call có thể đắt gấp 10-100 lần một request web
  thường.
- **Dễ "bill shock".** Một vòng lặp agent chạy sai, một spike traffic, một
  prompt nhồi quá nhiều context — hóa đơn nhảy vọt mà không ai nhận ra kịp.

### 1.3. InsightHub — hai loại chi phí LLM

InsightHub minh họa rõ điều này. Nó có **hai loại LLM call**:

| Loại call | Khi nào | Đặc điểm chi phí |
|---|---|---|
| **Embedding** | Mỗi khi ingest tài liệu (mỗi chunk) | Nhiều call nhỏ, tích lũy |
| **Generation** | Mỗi khi người dùng hỏi | Ít call hơn nhưng mỗi call đắt hơn |

Không kiểm soát cả hai → khó biết tiền chảy đi đâu.

---

## 2. Concept & Core Components

### 2.1. Token economics — ôn lại

LLM tính phí riêng cho **input token** và **output token**. Output thường đắt
hơn input nhiều lần. Giá thay đổi theo model — model mạnh đắt hơn model nhỏ.

### 2.2. Ba trụ cột FinOps cho LLM

| Trụ cột | Ý nghĩa |
|---|---|
| **Visibility** | Thấy được: đang tiêu bao nhiêu, ở đâu, cho cái gì |
| **Optimization** | Giảm cost mà không giảm chất lượng cần thiết |
| **Governance** | Đặt giới hạn, cảnh báo, ngăn bill shock |

### 2.3. LLM Gateway

LLM Gateway là một lớp trung gian đứng giữa ứng dụng và (các) LLM provider. Vai
trò:

- **Cost tracking tập trung** — mọi call đi qua gateway, đếm token một chỗ.
- **Model routing** — câu hỏi đơn giản route sang model rẻ, câu khó sang model mạnh.
- **Failover** — provider này lỗi thì chuyển provider khác.

Ví dụ: Requesty, LiteLLM, Helicone, Portkey.

---

## 3. Features — công cụ FinOps cho LLM

### 3.1. Cost visibility — đo token

Bước đầu tiên của FinOps là **đo được**. InsightHub đã expose sẵn:

- `insighthub_llm_tokens_total` (label: input / output) — token generation.
- `insighthub_embedding_tokens_total` — token embedding.

Từ metric token + đơn giá model → tính được cost theo thời gian, hiển thị trên
Grafana dashboard (Day 4).

### 3.2. Model routing — tối ưu chi phí

Không phải câu hỏi nào cũng cần model mạnh nhất:

| Loại tác vụ | Model phù hợp |
|---|---|
| Phân loại đơn giản, tóm tắt ngắn | Model nhỏ/rẻ (vd Haiku) |
| Hỏi đáp thông thường | Model trung (vd Sonnet) |
| Reasoning phức tạp | Model mạnh (vd Opus) |

Route đúng model cho đúng tác vụ → tiết kiệm đáng kể mà chất lượng không giảm ở
chỗ cần.

### 3.3. Budget alert

Đặt ngưỡng cảnh báo chi tiêu: vd "khi chi tiêu AI đạt 80% ngân sách tháng → cảnh
báo". Công cụ: AWS Budgets (nếu dùng Bedrock), spend limit trong Anthropic
Console, hoặc cảnh báo từ LLM gateway.

### 3.4. Observability cho cost

CloudWatch GenAI Observability (AWS) và các công cụ như Langfuse, Helicone cho
phép theo dõi cost + latency của LLM call ở mức chi tiết — gắn cost với từng
feature, từng người dùng.

---

## 4. Implementation — FinOps cho InsightHub

### 4.1. Quy trình

```
1. Visibility:   thêm panel cost vào Grafana dashboard (từ token metric)
2. Optimization: cân nhắc model routing (embedding rẻ, generation vừa đủ)
3. Governance:   đặt budget alert (AWS Budgets / Anthropic Console spend limit)
```

### 4.2. Trong khóa học

Day 6 dành ~15 phút cho FinOps — đủ để: hiểu khái niệm, thêm panel cost vào
dashboard, biết về LLM gateway và budget alert. Không sa đà vào cấu hình gateway
phức tạp — đó là chủ đề chuyên sâu riêng.

### 4.3. Liên hệ Day 1 — chọn model

Nhớ lại Day 1: Claude Code cho chọn model tier (Haiku/Sonnet/Opus). Quyết định
"dùng Sonnet cho việc thường ngày, Opus khi cần reasoning sâu" — đó **chính là**
model routing thủ công, và là quyết định FinOps đầu tiên học viên đã làm.

---

## 5. Best Practices

1. **Đo trước, tối ưu sau** — không có visibility thì không tối ưu được.
2. **Tách cost theo loại call** — embedding vs generation, để biết tiền đi đâu.
3. **Model routing** — đừng dùng model mạnh nhất cho mọi việc.
4. **Luôn có budget alert** — phòng bill shock, đặt ngay từ ngày đầu.
5. **Tận dụng cache** — context lặp lại (như CLAUDE.md) được cache, rẻ hơn.
6. **Gắn cost với feature** — biết feature nào tốn tiền để ưu tiên tối ưu.
7. **Giám sát thường xuyên** — cost không phải việc kiểm tra một lần.

### Anti-patterns

| Anti-pattern | Hậu quả |
|---|---|
| Không đo token | Không biết tiêu bao nhiêu, ở đâu |
| Dùng model mạnh nhất cho mọi tác vụ | Trả tiền gấp nhiều lần không cần thiết |
| Không đặt budget alert | Bill shock — phát hiện khi đã quá muộn |
| Nhồi cả codebase vào mỗi prompt | Token tăng 10-100x |
| Coi cost là việc kiểm tra một lần | Chi phí trôi dạt không kiểm soát |

---

## 6. Case Study — Vòng lặp agent và hóa đơn 2000 đô

**Bối cảnh điển hình (đã xảy ra với nhiều team năm 2025-2026):** một team triển
khai một AI agent tự động hóa một tác vụ DevOps. Agent chạy nền, lặp định kỳ.

Một lỗi logic khiến agent rơi vào **vòng lặp**: mỗi lần chạy, nó đọc lại toàn bộ
một thư mục lớn (nhồi vào context), gọi model **Opus** (model đắt nhất), không
có điều kiện dừng đúng. Mỗi vòng lặp tốn vài chục nghìn token. Agent lặp hàng
nghìn lần trong một cuối tuần.

Không ai nhận ra — vì:

- Không có **budget alert** → không có cảnh báo khi chi tiêu tăng vọt.
- Không có **cost visibility** → không có dashboard để ai đó tình cờ thấy.

Sáng thứ Hai, team phát hiện hóa đơn AI tăng thêm ~2000 đô cho một cuối tuần.

### Nếu áp dụng FinOps

- **Visibility:** dashboard cost sẽ cho thấy đường token đi lên dốc đứng từ tối
  thứ Sáu — ai đó nhìn dashboard sẽ thấy ngay.
- **Governance:** budget alert đặt ở 80% ngân sách sẽ kích hoạt sau vài giờ, không
  phải sau hai ngày.
- **Optimization:** nếu agent route sang model rẻ (Haiku) cho tác vụ đơn giản
  này, cùng một lỗi sẽ tốn ít hơn nhiều lần — đủ thời gian để phát hiện.

**Bài học:** FinOps cho LLM không phải "chuyện kế toán làm sau". Nó là một phần
của **vận hành an toàn** — giống như observability cảnh báo sự cố kỹ thuật,
FinOps cảnh báo "sự cố chi phí". Với LLM, một lỗi logic không chỉ gây bug — nó
gây hóa đơn. Đặt budget alert ngay từ ngày đầu tiên, không phải sau cú sốc đầu tiên.

---

## Tự kiểm tra trước buổi học

1. Vì sao LLM workload cần FinOps khác với hạ tầng cloud truyền thống?
2. Hai loại LLM call của InsightHub là gì? Đặc điểm chi phí mỗi loại?
3. LLM Gateway làm những việc gì?
4. Model routing tiết kiệm chi phí bằng cách nào?
5. Vì sao budget alert nên đặt từ ngày đầu, không phải sau khi bị bill shock?

---

## Đọc thêm (tùy chọn)

- FinOps Foundation — FinOps for AI
- Tài liệu LiteLLM / Requesty — LLM gateway
