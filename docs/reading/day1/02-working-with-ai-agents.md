# Day 1 — Tài liệu đọc trước · Topic 2
# Làm việc với AI Coding Agent: Prompting, Context & Token Economics

> **Thời gian đọc:** ~20 phút

---

## 1. Lý thuyết cơ bản — Context window

### 1.1. Context window là gì

Mọi LLM làm việc trong một "cửa sổ ngữ cảnh" (context window) — lượng văn bản
tối đa model xử lý được trong một lượt. Claude Opus/Sonnet 4.x có context tới
**1 triệu token** (beta). Nghe rất lớn, nhưng:

- Codebase thật dễ dàng vượt 1M token.
- Context càng đầy, model càng khó "chú ý" đúng chỗ (lost-in-the-middle).
- Token = tiền (xem mục 4).

→ Quản lý context là kỹ năng cốt lõi khi làm việc với AI agent, không phải chuyện
"cứ nhồi hết vào".

### 1.2. Agent quản lý context thế nào

Claude Code không nạp toàn bộ codebase. Nó:

- Đọc `CLAUDE.md` (context bền vững, luôn có).
- Đọc file theo nhu cầu (khi task cần).
- Dùng subagent cho exploration (context riêng, không làm bẩn context chính).
- Nén/tóm tắt context khi gần đầy (compaction).

---

## 2. Concept — Context Engineering

### 2.1. Định nghĩa

**Context engineering** là việc chủ động thiết kế *những gì agent biết* tại mỗi
thời điểm, để agent làm việc chính xác và hiệu quả. Gồm:

- **Cái gì đưa vào** context (file nào, tài liệu nào).
- **Cái gì giữ lại lâu dài** (CLAUDE.md, skills).
- **Cái gì tách riêng** (subagent cho task đọc nhiều file).

### 2.2. Ba tầng context trong Claude Code

| Tầng | Nội dung | Vòng đời |
|---|---|---|
| **Bền vững** | `CLAUDE.md`, `.claude/rules/*.md` | Mọi phiên |
| **Theo nhu cầu** | Skill (chỉ load khi description khớp task) | Khi liên quan |
| **Tạm thời** | File đọc trong phiên, kết quả tool call | Trong phiên |

**Progressive disclosure:** skill chỉ nạp khi cần — tài liệu tham khảo dài "gần
như miễn phí" cho tới khi được dùng. Đây là lý do nên đưa workflow lặp lại vào
*skill*, không nhồi vào CLAUDE.md.

---

## 3. Core Components của một prompt tốt

### 3.1. Cấu trúc prompt cho task DevOps

Một prompt hiệu quả cho agent thường có 4 phần:

```
[MỤC TIÊU]    Tách ingestion thành service riêng để scale độc lập.
[RÀNG BUỘC]   - Giữ nguyên schema DB
              - Tái sử dụng process_document(), không viết lại
              - Worker async — dùng run_in_executor cho code sync
[QUY TRÌNH]   Trình bày plan trước khi sửa file.
[VERIFY]      Sau khi xong, docker compose up + smoke-test.sh phải PASS.
```

### 3.2. Constraint-first

Nêu ràng buộc **trước** nội dung. Lý do: agent đọc tuần tự — ràng buộc đặt trước
sẽ định hình toàn bộ cách agent suy nghĩ. Nếu để ràng buộc ở cuối, agent có thể
đã "đi sai hướng" trước khi đọc tới.

### 3.3. Positive + negative examples

- **Positive:** "API trả về HTTP 202 ngay sau khi enqueue."
- **Negative:** "KHÔNG gọi hàm ingest đồng bộ trong request handler."

Cả hai cùng có giúp agent hiểu ranh giới rõ ràng.

---

## 4. Token Economics — vì sao quan trọng

### 4.1. Token = tiền

LLM tính phí theo token (input + output). Giá tham khảo 2026:

| Model | Input (1M token) | Output (1M token) |
|---|---|---|
| Claude Haiku | rẻ nhất | rẻ nhất |
| Claude Sonnet | ~$3 | ~$15 |
| Claude Opus | ~$5 | ~$25 |

Một phiên refactor có thể tốn vài chục nghìn → vài trăm nghìn token. Làm việc
cẩu thả (nhồi cả codebase vào mỗi prompt) → cost tăng 10-100x.

### 4.2. Vì sao CLI-first tiết kiệm token hơn

Agent IDE-first (Cursor...) thường gửi nhiều "editor state" (file đang mở, tab,
selection...). Agent CLI-first (Claude Code) gửi gọn hơn — chỉ những gì task cần.
Thực tế: Claude Code dùng ít token hơn đáng kể cho cùng một task.

### 4.3. Cache

Claude Code dùng prompt caching — phần context không đổi (như CLAUDE.md) được
cache, lần sau không tính phí đầy đủ. `/cost` hiển thị breakdown cache-hit.

### 4.4. Chiến lược cost-aware

| Tình huống | Lựa chọn |
|---|---|
| Việc thường ngày (fix bug, viết test) | Sonnet |
| Refactor lớn, reasoning sâu | Opus |
| Subagent exploration, tìm file | Haiku |
| Context lặp lại nhiều | Tận dụng cache — giữ CLAUDE.md ổn định |

---

## 5. Implementation — quy trình một phiên làm việc

### 5.1. Khởi động dự án mới với Claude Code

```bash
cd <project>
claude
> /init                          # sinh CLAUDE.md ban đầu
# (chỉnh tay CLAUDE.md: thêm ràng buộc, cắt phần thừa)
```

### 5.2. Một task điển hình

```
> Đọc <file A> và <file B>. Giải thích vấn đề X. Chưa sửa gì.
  ← (đọc câu trả lời, xác nhận agent hiểu đúng)
> Đề xuất plan giải quyết X. Ràng buộc: [...].
  ← (đọc plan, phê duyệt hoặc điều chỉnh)
> Thực hiện plan.
  ← (đọc diff, review)
> Chạy <verify command>.
  ← (xác nhận PASS)
```

### 5.3. Khi agent đi sai hướng

- **Dừng sớm.** Đừng để agent "đào" tiếp khi đã lệch.
- **Thu hẹp scope.** "Chỉ tập trung file X, đừng đụng file khác."
- **Reset context** nếu context đã quá nhiễu — bắt đầu phiên mới với prompt rõ hơn.

---

## 6. Best Practices

1. **Một task — một mục tiêu rõ ràng.** Đừng gộp 5 việc vào 1 prompt.
2. **Luôn yêu cầu plan trước khi sửa** với task không tầm thường.
3. **Constraint-first** — ràng buộc đặt đầu prompt.
4. **Verify bằng lệnh cụ thể**, không tin "trông có vẻ đúng".
5. **Giữ CLAUDE.md ổn định** để tận dụng cache.
6. **Theo dõi `/cost`** — biết mình đang tiêu bao nhiêu.
7. **Lưu lại prompt** đã dùng — vừa để tái sử dụng, vừa để chứng minh quy trình.

---

## 7. Case Study — Cùng task, hai cách làm

**Task:** thêm tính năng hiển thị điểm similarity của nguồn trong câu trả lời RAG.

### Cách A — prompt cẩu thả

```
> sửa app cho nó hiện similarity
```

Kết quả: agent không biết "app" là gì, sửa ở đâu, định dạng nào. Phải hỏi đi
hỏi lại nhiều lượt → tốn token, tốn thời gian, dễ sai.

### Cách B — prompt có cấu trúc

```
> [MỤC TIÊU] Hiển thị điểm similarity của từng nguồn trong câu trả lời chat.
  [PHẠM VI]  api/app/routers/chat.py trả thêm similarity;
             web/components/ChatPanel.tsx hiển thị bên cạnh tên file.
  [RÀNG BUỘC] Không đổi schema response cũ, chỉ thêm field.
  [QUY TRÌNH] Trình bày plan trước.
```

Kết quả: agent hiểu ngay, làm 1 lượt, đúng phạm vi. Ít token, ít vòng lặp.

**Bài học:** chi phí thật của AI agent không nằm ở giá token/đơn vị, mà ở **số
vòng lặp**. Prompt rõ = ít vòng lặp = nhanh và rẻ. Đầu tư 2 phút viết prompt tốt
tiết kiệm 20 phút sửa tới sửa lui.

---

## Tự kiểm tra trước buổi học

1. Context window lớn có phải lúc nào cũng tốt? Vì sao?
2. Progressive disclosure của skill nghĩa là gì?
3. Vì sao nên đặt ràng buộc ở đầu prompt (constraint-first)?
4. Chi phí thật khi dùng AI agent nằm ở đâu?
5. Khi nào chọn Haiku, khi nào chọn Opus?

---

## Đọc thêm (tùy chọn)

- Anthropic — "Effective context engineering for AI agents"
- Claude Code docs — Costs & model selection
