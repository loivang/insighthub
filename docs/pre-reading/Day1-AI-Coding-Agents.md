# Pre-Reading — Day 1: AI Coding Agents & AI-Native DevOps

> **Module 7 — AI-Native DevOps** · Pillar A: Develop with AI
> Tài liệu đọc trước buổi học. Thời gian đọc ước tính: 35-45 phút.
> Mục tiêu: nắm lý thuyết nền để vào buổi thực hành không bỡ ngỡ.

---

## Mục lục

1. [Bối cảnh: Paradigm shift của DevOps 2023 → 2026](#1-bối-cảnh)
2. [Concept: AI Coding Agent là gì](#2-concept)
3. [Core Components của một Coding Agent](#3-core-components)
4. [Landscape: các công cụ và khi nào dùng](#4-landscape)
5. [Features: từ cơ bản đến nâng cao](#5-features)
6. [Implementation: cách agent vận hành](#6-implementation)
7. [Best Practices](#7-best-practices)
8. [Case Study](#8-case-study)
9. [Thuật ngữ & Đọc thêm](#9-thuật-ngữ)

---

## 1. Bối cảnh

### 1.1. Ba thế hệ "AI cho lập trình"

| Thế hệ | Thời kỳ | Đặc trưng |
|---|---|---|
| **Gen 1 — Autocomplete** | 2021-2023 | GitHub Copilot bản đầu. Gợi ý dòng/hàm tiếp theo. Người vẫn lái toàn bộ. |
| **Gen 2 — Chat-assisted** | 2023-2024 | ChatGPT, Copilot Chat. Hỏi đáp, sinh đoạn code. Vẫn copy-paste thủ công. |
| **Gen 3 — Agentic** | 2025-2026 | Claude Code, Cursor Agent, Codex. Agent **tự đọc codebase, sửa nhiều file, chạy lệnh, test, lặp lại**. |

Sự khác biệt cốt lõi của Gen 3: agent có **vòng lặp tự chủ** (agentic loop) — nó không chỉ trả lời, nó *hành động* rồi *quan sát kết quả* rồi *hành động tiếp*.

### 1.2. Vì sao điều này quan trọng với DevOps engineer

Dữ liệu thị trường (Requesty, Jan 2026): job posting yêu cầu kỹ năng AI coding tool **tăng 340%** trong 12 tháng; job "pure implementation" (chỉ code tay) **giảm 17%**.

Thông điệp: giá trị của DevOps engineer 2026 dịch chuyển từ *"người gõ lệnh"* sang *"người chỉ huy AI agent"* — biết giao việc gì cho agent, review thế nào, và giữ phán đoán kỹ thuật ở đâu.

### 1.3. AI-Native DevOps — định nghĩa làm việc

> **AI-Native DevOps** không phải là "thêm AI vào DevOps". Đó là tư duy đặt AI agent làm **cộng tác viên mặc định** trong mọi khâu: viết IaC, dựng pipeline, vận hành, điều tra sự cố, bảo mật.

Phản đề cần tránh: "AI-aware DevOps" — chỉ biết AI tồn tại, thỉnh thoảng hỏi ChatGPT. Khóa học này hướng tới AI-Native.

---

## 2. Concept

### 2.1. AI Coding Agent — định nghĩa

Một **AI Coding Agent** là phần mềm dùng LLM làm "bộ não", có khả năng:

- **Đọc** codebase (file, cấu trúc, git history).
- **Lập kế hoạch** chia nhỏ một task lớn.
- **Hành động**: sửa file, chạy lệnh shell, gọi tool.
- **Quan sát** kết quả (output lệnh, lỗi test) và **lặp lại** cho tới khi đạt mục tiêu.

Khác autocomplete: autocomplete đoán *token tiếp theo*; agent theo đuổi *một mục tiêu* qua nhiều bước.

### 2.2. Agentic Loop — trái tim của coding agent

```
   ┌─────────────────────────────────────────┐
   │                                         │
   ▼                                         │
[Perceive]  →  [Reason/Plan]  →  [Act]  →  [Observe]
 đọc context    LLM quyết định    chạy      đọc kết quả,
 hiện tại       bước tiếp theo    tool      lỗi, output
   │                                         │
   └─────────── lặp tới khi đạt goal ─────────┘
```

Mỗi vòng lặp, agent: nhìn trạng thái → LLM suy luận → thực thi 1 hành động → đọc kết quả → quyết định tiếp. Dừng khi đạt mục tiêu hoặc hết "ngân sách" (số bước/token).

### 2.3. Vì sao agent đôi khi sai

Hiểu để dùng đúng:

- LLM có thể **hallucinate** — bịa tên API, argument không tồn tại.
- Context window hữu hạn — codebase quá lớn, agent "quên" phần đã đọc.
- Không có hiểu biết về *ý định kinh doanh* — chỉ làm đúng chữ trong prompt.

→ Đây là lý do **human review** là bắt buộc, không phải tùy chọn.

---

## 3. Core Components

Một coding agent hiện đại gồm các thành phần:

| Thành phần | Vai trò |
|---|---|
| **Model (LLM)** | "Bộ não" suy luận. Claude Opus 4.7, GPT-5.5, Gemini 3.1... |
| **Harness** | Lớp điều phối vòng lặp agentic, quản lý context, gọi tool. Đây là phần làm nên sự khác biệt giữa các công cụ. |
| **Tools** | Khả năng hành động: đọc/ghi file, chạy shell, search code, gọi MCP server. |
| **Context management** | Quyết định đưa gì vào context window (file nào, lịch sử nào). |
| **Memory / Project context** | `CLAUDE.md`, `.cursorrules` — context bền vững giữa các phiên. |
| **Permission / Safety layer** | Hỏi xác nhận trước hành động nguy hiểm, sandbox. |

**Điểm quan trọng:** cùng một model (vd Claude Opus 4.7), nhưng *harness* khác nhau cho kết quả khác nhau. Benchmark Terminal-Bench 2.0: cùng model, harness Claude Code đạt 92.1%, harness khác thấp hơn nhiều. Harness = "tay nghề" của agent.

---

## 4. Landscape

### 4.1. Ba nhóm công cụ

| Nhóm | Đại diện | Kiến trúc | Sweet spot |
|---|---|---|---|
| **CLI-first** | Claude Code, Aider, Codex CLI, Gemini CLI | Chạy trong terminal, truy cập trực tiếp filesystem/shell/git | DevOps workflow, refactor lớn, automation, đưa vào pipeline |
| **IDE-first** | Cursor 3, Windsurf, Copilot | Tích hợp trong editor, inline + agent mode | Pair-programming, sửa nhanh, exploration |
| **Cloud/async** | Devin, Codex Cloud, Cursor Cloud Agents | Chạy nền trên VM sandbox, giao task qua issue/PR | Task dài, chạy song song nhiều task, "giao việc rồi đi làm việc khác" |

### 4.2. So sánh nhanh (Q2 2026)

| Công cụ | Mạnh nhất ở | Lưu ý |
|---|---|---|
| **Claude Code** | Refactor lớn (20+ file), debug phức tạp, context 1M token, terminal-native, MCP-centric | Lựa chọn chính của khóa học |
| **Cursor 3** | IDE UX, Agents Window chạy nhiều agent song song | Tốt cho daily coding |
| **OpenAI Codex** | Async delegation, cloud sandbox, tích hợp ChatGPT | "Giao task rồi quên" |
| **Aider** | Open-source, git-first, model-agnostic | Miễn phí, BYOK |

### 4.3. Vì sao khóa học chọn Claude Code

- **Terminal-native** — DevOps engineer sống trong terminal; agent ở đúng nơi làm việc.
- **Scriptable** — gọi được trong CI/CD pipeline (sẽ dùng ở Day 3).
- **`CLAUDE.md`** — context bền vững; agent "nhớ" kiến trúc dự án giữa các phiên.
- **MCP-centric** — tích hợp sâu MCP, nền tảng cho Day 2.
- **Token-efficient** — CLI không phải gửi toàn bộ editor state, tiết kiệm cost (~5.5x so với IDE-first cho cùng task).

> Lưu ý nghề nghiệp: không có công cụ "tốt nhất tuyệt đối". Senior dev 2026 thường dùng **2 công cụ song song** — vd Claude Code cho task khó + Cursor cho daily. Chọn theo *hình dạng công việc*.

---

## 5. Features — từ cơ bản đến nâng cao

### 5.1. Cơ bản

- **Đọc & giải thích code** — "giải thích file này làm gì".
- **Sinh code** — tạo file/hàm mới theo mô tả.
- **Sửa lỗi** — đọc stack trace, đề xuất fix.

### 5.2. Trung cấp

- **Multi-file refactor** — sửa đồng bộ nhiều file, giữ nhất quán.
- **Chạy & đọc lệnh** — tự chạy test, đọc kết quả, sửa tiếp.
- **Project context** (`CLAUDE.md`) — agent đọc file này mỗi phiên: kiến trúc, quy ước, lệnh hay dùng, "forbidden patterns".

### 5.3. Nâng cao

- **Subagents / Agent Teams** — agent chính chia task, spawn agent con với tool scope hẹp, gộp kết quả. Agent con càng hẹp quyền → càng đáng tin.
- **Computer use** — agent point-and-click qua UI, chụp screenshot, làm việc khó script hóa.
- **MCP integration** — kết nối tool/data ngoài (Day 2).
- **Async background agents** — giao task, agent chạy nền, trả PR khi xong.

### 5.4. Benchmark — đọc sao cho đúng

| Benchmark | Đo gì | Lưu ý |
|---|---|---|
| **SWE-bench Verified** | Giải GitHub issue thật | Đã bị "contamination" — training data trùng test set, điểm bị thổi phồng |
| **SWE-bench Pro** | 2000+ bài, không có trong public training data | Sạch hơn, điểm thấp hơn nhưng *trung thực* hơn |
| **Terminal-Bench 2.0** | Thực thi đa bước trong terminal thật | Sát với agentic DevOps work nhất |

Bài học: đừng tin điểm benchmark mù quáng. Benchmark mới hơn + chưa nhiễm dữ liệu = đáng tin hơn.

---

## 6. Implementation — agent vận hành thế nào

### 6.1. Một phiên Claude Code điển hình

```
$ cd my-project
$ claude                    # khởi động agent trong thư mục dự án
> /init                     # agent quét codebase, sinh CLAUDE.md
> Refactor module X: ...     # giao task bằng natural language
  [agent đọc file liên quan]
  [agent trình bày PLAN]     # ← human REVIEW ở đây
  [human approve]
  [agent sửa file, chạy test]
  [agent báo kết quả]
> ...
```

### 6.2. CLAUDE.md — context engineering

`CLAUDE.md` ở thư mục gốc, agent đọc mỗi phiên. Nội dung tốt gồm:

- **Kiến trúc** — các service, mối quan hệ.
- **Quy ước** — code style, commit convention.
- **Lệnh hay dùng** — build, test, deploy.
- **Ràng buộc** — "không hardcode secret", "pin version X".

Nguyên lý: **context tốt = agent chính xác hơn, hỏi lại ít hơn, ít hallucinate hơn**. Đầu tư vào `CLAUDE.md` là đầu tư có lãi.

### 6.3. BYOK & gateway

Claude Code dùng Anthropic API mặc định, nhưng cấu hình được endpoint khác (qua biến môi trường). Team thường route traffic qua **LLM gateway** để tracking cost tập trung — sẽ học kỹ ở Day 6.

---

## 7. Best Practices

### 7.1. Vòng lặp an toàn

```
Prompt rõ ràng → Agent đề xuất PLAN → Human REVIEW → Approve → Agent thực thi → Verify
```

**Không bao giờ** để agent tự apply thay đổi lớn mà không xem plan.

### 7.2. Viết prompt tốt cho refactor

- Mô tả **mục tiêu** (output mong muốn), không chỉ liệt kê task.
- Nêu **ràng buộc rõ ràng**: "giữ nguyên schema DB", "không đổi API contract".
- Yêu cầu agent **trình bày plan trước khi sửa**.
- Cung cấp **ví dụ** nếu có pattern cụ thể muốn theo.

### 7.3. Review code của agent như review junior

- Đọc *vì sao* agent làm vậy, không chỉ *nó làm gì*.
- Hỏi lại agent đoạn không hiểu — đừng approve mù.
- Chạy test, đối chiếu với yêu cầu thật.

### 7.4. Anti-patterns cần tránh

| Anti-pattern | Hậu quả |
|---|---|
| "Vibe-coding" — approve mọi thứ không đọc | Code chạy nhưng không ai hiểu, nợ kỹ thuật |
| Prompt mơ hồ | Agent đoán sai ý định |
| Không có `CLAUDE.md` | Agent lặp lại sai lầm, hỏi đi hỏi lại |
| Giao task quá lớn 1 lần | Agent lạc hướng, context tràn |

### 7.5. Token efficiency

Token = tiền (Day 6). Mẹo: dùng `CLAUDE.md` để giảm context lặp lại; chia task vừa phải; dùng model phù hợp (không phải task nào cũng cần model mạnh nhất).

---

## 8. Case Study

### 8.1. Refactor InsightHub — chính là bài Day 1

InsightHub v0 cố ý có điểm yếu kiến trúc: việc xử lý tài liệu (chunk + embed) chạy **đồng bộ** ngay trong API request handler. Hệ quả: upload file lớn → request bị block, có thể timeout; không scale worker độc lập; không có queue để observe.

**Bài toán Day 1:** dùng Claude Code refactor — tách phần xử lý này thành service `ingestion-worker` riêng, đẩy job qua Redis queue (ARQ).

**Vì sao đây là case study tốt:**
- Đây là refactor *thật* trên codebase nhiều file — đúng sweet spot của Claude Code.
- Có ràng buộc rõ (giữ schema DB, tái sử dụng hàm `process_document`) — luyện viết prompt constraint-first.
- Kết quả tạo ra kiến trúc async cần cho bài Observability (Day 4) — một refactor, hai mục đích.

### 8.2. Bài học từ ngành — "Codex for volume, Claude for depth"

Nhiều team 2026 dùng cả hai: agent cloud async (Codex/Devin) cho task khối lượng lớn nhưng đơn giản; Claude Code cho task khó cần hiểu sâu codebase. Đây là minh họa nguyên tắc *"match agent to workload"* — chọn công cụ theo hình dạng công việc, không theo hype.

---

## 9. Thuật ngữ & Đọc thêm

### Thuật ngữ

- **Agentic loop** — vòng lặp perceive-reason-act-observe của agent.
- **Harness** — lớp điều phối agent quanh model; quyết định "tay nghề".
- **Context window** — lượng token tối đa model xử lý 1 lần.
- **CLAUDE.md** — file context bền vững cho Claude Code.
- **BYOK** — Bring Your Own Key.
- **Hallucination** — model bịa thông tin không có thật.
- **Subagent** — agent con tool-scope hẹp, do agent chính spawn.

### Đọc thêm (khuyến nghị trước buổi)

- Anthropic — "Building effective AI agents" (engineering blog).
- Anthropic — "Effective context engineering for AI agents".

### Tự kiểm tra trước khi đến lớp

1. Agentic loop gồm những bước nào?
2. Tại sao cùng model nhưng harness khác cho kết quả khác?
3. `CLAUDE.md` dùng để làm gì?
4. Vì sao human review là bắt buộc?
5. InsightHub v0 có điểm yếu kiến trúc gì, và Day 1 sẽ sửa thế nào?

---

*Pre-reading Day 1 — Module 7 AI-Native DevOps. Đọc xong, bạn đã sẵn sàng cho buổi thực hành.*
