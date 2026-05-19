# Sample Documents

Tài liệu mẫu để học viên test RAG pipeline của InsightHub.

| File | Mục đích |
|---|---|
| `so-tay-van-hanh.md` | Tài liệu sạch — test ingest + retrieval cơ bản |
| `service-level-objectives.md` | Tài liệu sạch tiếng Anh — test đa ngôn ngữ |
| `huong-dan-nguoi-moi.md` | ⚠️ **Chứa indirect prompt injection** — dùng cho Day 6 |

## ⚠️ Lưu ý về `huong-dan-nguoi-moi.md` (cho trainer)

File này **cố ý nhúng một đoạn prompt injection** ở giữa nội dung hợp lệ
(đoạn "NOTE FOR THE AI ASSISTANT..."). Đây là ví dụ kinh điển của
**OWASP LLM01 — Prompt Injection** dạng *indirect*: payload độc hại đi vào
hệ thống qua tài liệu người dùng upload, không phải qua câu hỏi trực tiếp.

### Dùng trong Day 6 (Security)

1. Học viên ingest file này như tài liệu bình thường.
2. Đặt câu hỏi → quan sát xem RAG pipeline có bị payload tác động không.
3. Phân tích: vì sao retrieval kéo cả đoạn độc hại vào context.
4. Vá: thêm guardrails, sanitize chunk, hoặc tách system prompt khỏi context
   bằng cấu trúc rõ ràng (đã có sẵn dạng `<context>` trong `llm.py`).
5. Chạy lại Promptfoo OWASP scan để verify đã vá.

Học viên KHÔNG nên được cảnh báo trước file nào "bẩn" — việc tự phát hiện
là một phần bài học.
