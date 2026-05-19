# Day 1 — Tài liệu đọc trước · Topic 1
# AI-Native DevOps & AI Coding Agents Landscape

> **Đối tượng:** Học viên module AI-Native DevOps · **Thời gian đọc:** ~25 phút
> Đọc trước buổi học để nắm lý thuyết. Buổi học sẽ tập trung thực hành.

---

## 1. Lý thuyết cơ bản

### 1.1. DevOps đang thay đổi như thế nào

DevOps truyền thống tối ưu vòng lặp: code → build → test → deploy → operate → monitor.
Mỗi khâu, kỹ sư viết script, cấu hình pipeline, đọc log bằng tay.

Từ 2024-2026, một lớp mới chen vào giữa kỹ sư và công việc: **AI agent**. Kỹ sư
không còn trực tiếp gõ từng dòng Terraform hay từng lệnh `kubectl` — họ **mô tả
mục tiêu**, AI agent thực thi, kỹ sư **review và phê duyệt**.

Đây không phải "AI hỗ trợ gõ code nhanh hơn" (autocomplete). Đây là dịch chuyển
vai trò: từ **người thực thi** sang **người điều phối** (orchestrator).

### 1.2. Ba thuật ngữ cần phân biệt

| Thuật ngữ | Nghĩa |
|---|---|
| **AI-assisted** | AI gợi ý, người vẫn làm chính (Copilot autocomplete) |
| **AI-augmented** | AI làm phần lớn công việc, người review (Claude Code refactor) |
| **AI-native** | Quy trình được thiết kế quanh AI agent ngay từ đầu |

Mục tiêu của module: đưa học viên từ *AI-assisted* lên *AI-augmented*, và hiểu
tư duy *AI-native*.

### 1.3. Vì sao điều này quan trọng với sự nghiệp

Số liệu thị trường (2026): tin tuyển dụng yêu cầu kỹ năng AI agent tăng **+340%**
trong 12 tháng; các vai trò "implementation thuần" (chỉ viết code theo spec) giảm
~17%. Khoảng 4% commit công khai trên GitHub (~135.000/ngày) được tạo bởi AI
coding agent — tăng gần 43.000 lần trong 13 tháng.

Kỹ sư DevOps không biết dùng AI agent năm 2026 giống như kỹ sư không biết dùng
Git năm 2015 — không phải "thiếu kỹ năng phụ", mà là thiếu kỹ năng nền.

---

## 2. Concept & Core Components

### 2.1. AI Coding Agent là gì

Một AI Coding Agent là hệ thống có khả năng:

- **Đọc** codebase (nhiều file, hiểu cấu trúc).
- **Lập kế hoạch** (plan) cho một task phức tạp.
- **Thực thi** — gọi tool: chỉnh file, chạy lệnh shell, chạy test.
- **Tự sửa** — đọc kết quả (lỗi test, output), điều chỉnh.

Khác với autocomplete (chỉ đoán dòng tiếp theo), agent chạy **vòng lặp tác tử**
(agentic loop): quan sát → suy nghĩ → hành động → quan sát lại.

### 2.2. Phân loại AI Coding Agent

| Nhóm | Đại diện | Cơ chế | Điểm mạnh | Điểm yếu |
|---|---|---|---|---|
| **IDE-first** | Cursor, Windsurf | Tích hợp trong editor | Trực quan, vòng lặp nhanh khi đang code | Tốn token (gửi nhiều editor state) |
| **CLI-first** | Claude Code, Aider, Codex CLI | Chạy trong terminal | Scriptable, đưa vào pipeline được, token-efficient | Không có giao diện trực quan |
| **Cloud / async** | Devin, Codex Cloud | Chạy nền trên cloud | Task dài, chạy song song | Khó kiểm soát realtime |

**Vì sao khóa học chọn CLI-first (Claude Code):**

1. Kỹ sư DevOps làm việc chính trong terminal.
2. CLI scriptable → nhúng được vào CI/CD (sẽ dùng ở Day 3).
3. Token-efficient → quan trọng khi tính cost (Day 6).
4. Hỗ trợ chế độ non-interactive (`claude -p "..."`) cho automation.

### 2.3. Core components của Claude Code

Claude Code không chỉ là "chat trong terminal". Nó là một nền tảng có 5 hệ thống:

| Component | Vai trò |
|---|---|
| **Agentic loop** | Vòng lặp quan sát-suy nghĩ-hành động |
| **CLAUDE.md** | "Bộ nhớ dự án" — context bền vững giữa các phiên |
| **Tools & permissions** | Quyền chỉnh file, chạy lệnh — có kiểm soát |
| **MCP** | Kết nối tool/data bên ngoài (Day 2) |
| **Subagents & Hooks** | Mở rộng — agent con + tự động hóa lifecycle |

---

## 3. Features chính

### 3.1. CLAUDE.md — bộ nhớ dự án

Claude Code đọc `CLAUDE.md` ở thư mục gốc mỗi phiên làm việc. File này chứa
kiến thức về dự án mà agent cần biết: kiến trúc, quy ước code, lệnh hay dùng,
ràng buộc kỹ thuật.

**Nguyên tắc viết CLAUDE.md đúng (theo Anthropic + cộng đồng 2026):**

- **Chạy `/init` trước** — để Claude Code tự quét codebase, sinh bản nháp. Đừng
  viết từ con số 0, bạn sẽ quên nhiều thứ.
- **Giữ ngắn — dưới ~150-200 dòng.** Quá dài thì agent "bỏ qua nửa file" vì các
  quy tắc quan trọng bị chìm trong nhiễu. Claude theo sát đáng tin khoảng 150
  instruction.
- **WHAT / WHY / HOW** — mô tả dự án làm gì, vì sao quyết định kỹ thuật, làm thế nào.
- **Mỗi dòng phải "đáng giá"** — nếu Claude vốn đã làm đúng mà không cần dòng đó,
  hãy xóa.

### 3.2. Chế độ chạy

```bash
claude                    # interactive — phiên hội thoại
claude -p "Explain this"  # non-interactive — one-off, cho script/CI
claude -p "..." --output-format json   # output có cấu trúc, parse được
```

### 3.3. Model tiers

| Model | Dùng khi |
|---|---|
| **Opus** | Reasoning phức tạp, refactor lớn, kiến trúc |
| **Sonnet** | Workhorse hằng ngày — implement, fix bug, viết test, review |
| **Haiku** | Nhanh, rẻ (~5x rẻ hơn Opus) — exploration, subagent đơn giản |

Nguyên tắc cost-aware: dùng Sonnet cho phần lớn việc, Opus khi thực sự cần
reasoning sâu, Haiku cho subagent exploration.

### 3.4. Subagents (nâng cao — sẽ dùng dần)

Subagent là một agent con, chạy trong **context riêng biệt**, với **tool scope
hẹp**. Định nghĩa trong `.claude/agents/`. Dùng khi:

- Task cần đọc nhiều file mà không muốn làm "bẩn" context chính.
- Cần chuyên môn hóa: 1 subagent chỉ review security, 1 subagent chỉ chạy test.

Subagent scope càng hẹp → càng tập trung và đáng tin.

### 3.5. Hooks (nâng cao)

Hook là script chạy khi có sự kiện (PreToolUse, PostToolUse, UserPromptSubmit...).
Khác với CLAUDE.md (advisory — agent theo ~70%), hook là **deterministic** —
chạy chắc chắn, không hallucinate. Dùng cho: chặn lệnh nguy hiểm, chạy lint/test
tự động, ghi audit mọi tool call.

> **Quy tắc:** Bất cứ thứ gì *phải luôn luôn xảy ra* → dùng hook, không dùng prompt.

---

## 4. Implementation — vòng lặp làm việc đúng

### 4.1. Mô hình Research → Plan → Execute → Review → Ship

Cách làm việc với agent ở mức production (không phải "vibe coding"):

```
Research → Plan → Execute → Review → Ship
   │         │       │         │        │
 đọc hiểu   lập kế   agent    Claude   PR +
 codebase   hoạch    chạy     khác     CI review
                              review
```

- **Vibe coding:** mô tả 1 câu, để agent làm hết, ship luôn. Được cho prototype,
  vỡ trận ở production.
- **Agentic engineering:** điều phối agent qua vòng lặp có plan, có review, có
  test. Con người là **người giám sát**, không phải người gõ phím.

### 4.2. Vòng lặp an toàn khi refactor

```
Prompt rõ ràng → Agent trình bày PLAN → Người REVIEW plan
   → Approve → Agent thực thi → VERIFY (test/script) → Commit
```

Điểm mấu chốt: **đọc plan trước khi cho agent sửa**. Review một AI agent giống
review một junior developer.

### 4.3. Prompt tốt cho task DevOps

| Thành phần | Ví dụ |
|---|---|
| Mục tiêu (không chỉ task) | "Tách ingestion thành service riêng để scale độc lập" |
| Ràng buộc rõ ràng | "Giữ nguyên schema DB", "không đổi API contract" |
| Yêu cầu plan trước | "Trình bày plan trước khi sửa file" |
| Tiêu chí verify | "Sau khi xong, `smoke-test.sh` phải PASS" |

---

## 5. Best Practices

1. **`/init` rồi mới chỉnh tay CLAUDE.md** — không viết từ đầu.
2. **CLAUDE.md ngắn, mỗi dòng đáng giá** — dài thì bị bỏ qua.
3. **Verify mọi thứ** — agent tạo code "trông hợp lý" nhưng có thể không xử lý
   edge case. Không verify được thì không ship.
4. **Scope hẹp khi cho agent "investigate"** — nếu không, agent đọc hàng trăm
   file làm đầy context. Dùng subagent cho exploration.
5. **Đừng micromanage** — "paste cái bug, nói fix, đừng chỉ đạo cách làm".
6. **Hook cho thứ bắt buộc** — lint, test, security, audit.
7. **Lưu prompt log** — để chứng minh quá trình AI-augmented (cần cho Day 7).

### Anti-patterns cần tránh

| Anti-pattern | Hậu quả | Cách sửa |
|---|---|---|
| CLAUDE.md quá dài | Agent bỏ qua nửa file | Cắt gọn, chuyển rule thành hook |
| Trust-then-ship | Code lỗi edge case lọt production | Luôn có test/script verify |
| Infinite exploration | Agent đọc hàng trăm file, đầy context | Scope hẹp, dùng subagent |
| Vibe coding vào prod | Không kiểm soát chất lượng | Theo vòng Research→Plan→Execute→Review→Ship |

---

## 6. Case Study — Refactor một monolith bằng AI agent

**Bối cảnh:** InsightHub (project xuyên suốt khóa học) ở phiên bản v0 có một
điểm yếu cố ý: việc xử lý tài liệu (chunk + embed) chạy **đồng bộ** ngay trong
API request handler. Upload file lớn → request bị block, có thể timeout.

**Cách tiếp cận truyền thống:** kỹ sư đọc code, tự thiết kế lại, viết worker mới,
sửa API, viết Dockerfile, cập nhật docker-compose — vài giờ.

**Cách AI-augmented:**

1. *Research:* yêu cầu agent đọc `ingestion.py` + `documents.py`, giải thích
   điểm yếu. (Không sửa gì — chỉ phân tích.)
2. *Plan:* yêu cầu agent đề xuất plan tách `ingestion-worker` thành service riêng
   dùng hàng đợi Redis. Đọc kỹ plan.
3. *Execute:* agent tách worker, sửa API thành enqueue job, viết Dockerfile.
4. *Review:* đọc diff, kiểm tra agent có giữ schema DB không, có xử lý đúng
   sync-trong-async không.
5. *Ship:* chạy `smoke-test.sh`, commit, tạo PR.

**Bài học:** AI agent rút thời gian từ vài giờ xuống vài chục phút — *nhưng chỉ
khi kỹ sư review từng bước*. Nếu để agent tự apply không review, lỗi tinh vi
(ví dụ gọi hàm sync chặn event loop của worker async) sẽ lọt qua.

---

## Tự kiểm tra trước buổi học

Bạn nên trả lời được:

1. Phân biệt AI-assisted, AI-augmented, AI-native.
2. Vì sao khóa học chọn CLI-first agent thay vì IDE-first?
3. CLAUDE.md dùng để làm gì? Vì sao không nên viết dài?
4. Vòng lặp Research → Plan → Execute → Review → Ship gồm gì?
5. Khi nào dùng hook thay vì viết quy tắc vào CLAUDE.md?

---

## Đọc thêm (tùy chọn)

- Anthropic — "Building effective AI agents" (engineering blog)
- Anthropic — Claude Code best practices (docs chính thức)
- Anthropic — "Effective context engineering for AI agents"
