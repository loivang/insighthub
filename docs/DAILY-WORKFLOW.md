# Daily Workflow — InsightHub Running Project

> Quy trình submission + grading cho 7 ngày Module 7.
> Đọc 1 lần — dùng xuyên suốt.

---

## Timeline 1 ngày điển hình

```
ĐÊM TRƯỚC (1 giờ):
  📖 Đọc docs/pre-reading/DayN.md (~60-90 phút theo Day)
  📖 Skim docs/lab-guides/DayN.md (overview workflow)

NGÀY HỌC (2.5 giờ tại lớp):
  ⏰ 0:00-0:15 — Recap & Hook (15')
  ⏰ 0:15-0:55 — Concept deep dive (40')
  ⏰ 0:55-1:30 — Best practice + case study (35')
  ⏰ 1:30-2:15 — Live demo + hands-on lab (45')
  ⏰ 2:15-2:30 — Wrap-up + Day N+1 prep (15')

SAU LỚP (1-2 giờ homework):
  💻 Hoàn thiện artifact theo lab guide
  ✅ Chạy bash scripts/verify-day-N.sh
  📤 Submit Slack #day{N}-submissions trước 23:59
  📊 Trainer chấm async trong 24h → return rubric Slack DM
```

---

## Daily Submission Checklist

Trước khi submit mỗi Day:

```bash
# 1. Verify
bash scripts/verify-day-N.sh
# → Phải PASS tất cả Must-have

# 2. Commit
git add -A
git status                # check không commit nhầm .env, *.log
git commit -m "feat(day-N): <short description>

<longer description if needed>

AI-Augmented: Claude Code (Sonnet 4.6)
Prompt log: ai-prompts/day{N}.md"

# 3. Push branch
git push origin day{N}-<topic>

# 4. Create PR
gh pr create \
  --title "[Day N] <Topic>" \
  --body "See ai-prompts/day{N}.md for AI workflow.

  Verify output:
  $(bash scripts/verify-day-N.sh 2>&1 | tail -10)"

# 5. Submit Slack
```

### Submission template Slack

Post vào `#day{N}-submissions`:

```
Day {N} — <Tên của bạn>

✓ Repo: https://github.com/<u>/insighthub
✓ Branch: day{N}-<topic>
✓ PR: https://github.com/<u>/insighthub/pull/<id>
✓ AI Prompt log: <URL ai-prompts/day{N}.md>
✓ Artifacts:
   - <Artifact 1 URL or description>
   - <Artifact 2 URL>
✓ Verify output: bash scripts/verify-day-{N}.sh
   [paste last 5 lines: X PASS / Y FAIL]

[Optional] Self-eval Level (1-4):
  Dim X: Level 3 (because ...)
```

---

## Branch & Commit Convention

### Branch naming

```
day{N}-<topic-short>

Examples:
day1-refactor
day2-mcp
day3-terraform
day4-observability
day5-chatops-bot
day6-security-finops
day7-showcase
```

### Commit format (Conventional Commits)

```
<type>(<scope>): <short description>

<optional longer body>

<optional footer>
```

**Types**:
- `feat`: feature mới
- `fix`: bug fix
- `chore`: housekeeping (deps update, formatting)
- `refactor`: refactor không thêm feature
- `docs`: chỉ document
- `test`: tests
- `ci`: CI/CD config
- `perf`: performance optimization

**Examples**:
```
feat(ingestion): tách ingestion-worker + Redis queue

- Add ingestion-worker service with ARQ
- Convert /upload to async enqueue
- Add Redis to docker-compose
- Preserve API contract (request/response shape)
- All pytest tests pass

AI-Augmented: Claude Code (Sonnet 4.6)
Prompt log: ai-prompts/day1.md
```

```
fix(security): sanitize hidden Unicode in user input

- Strip zero-width spaces and combining marks
- Add unit test for injection patterns
- Reduces Promptfoo HIGH findings 5 → 0

AI-Augmented: Claude Code (Sonnet 4.6)
```

```
chore(deps): pin terraform-aws-modules to 20.0

- Prevent breaking changes from float versions
- Update lock file
```

### PR Title format

```
[Day N] <Topic>

Examples:
[Day 1] Refactor ingestion async + Redis queue
[Day 2] Add .mcp.json with 4+ MCP servers
[Day 3] Terraform module + GitHub Actions pipeline
[Day 4] Observability stack + anomaly rules + AI RCA
[Day 5] ChatOps bot with MCP backend
[Day 6] OWASP red team + LLM gateway + cost dashboard
[Day 7] Final showcase
```

---

## AI Prompt Log convention

File: `ai-prompts/day{N}.md` — bắt buộc submit mỗi Day.

### Template

```markdown
# Day {N} AI Prompts

## Context
Brief: what I was trying to accomplish today.

---

## Prompt 1 — <Title>

**Tool**: Claude Code (Sonnet 4.6)
**Time**: 2026-05-19 10:23 ICT
**Cost**: $0.12 (per /cost)

**Prompt**:
```
[Paste prompt with Constraint-first 4-part]

## Mục tiêu
...

## Ràng buộc
...

## Tiêu chí thành công
...

## Ví dụ pattern (nếu có)
...
```

**Why this prompt worked / didn't work**:
- ✅ Constraint-first helped focus
- ✅ "Trình bày PLAN trước" prevented vibe-coding
- ❌ Forgot to specify error handling — agent over-engineered retry logic

**What I changed in agent's output**:
- Removed unnecessary `try/except`
- Renamed variable for consistency
- Added type hint that agent missed

---

## Prompt 2 — <Title>

[Same structure]

---

## Prompt 3 — <Title>

[Same structure]

---

## Lessons learned today

3 things I took away about working with AI:
1. ...
2. ...
3. ...
```

### Tại sao bắt buộc Prompt log

1. **Chống vibe-coding** — viết log = bắt buộc dừng lại nghĩ "tôi đã làm gì với AI".
2. **Q&A Day 7** — trainer sẽ hỏi "show me prompt log — best vs worst prompt".
3. **Audit trail** — production: PR template có "AI Contribution" section là chuẩn 2026.
4. **Self-improve** — đọc lại sau 3 tháng thấy prompt cũ ngây ngô.

---

## Trainer Async Grading Flow

```
You submit Slack #day{N}-submissions
       ↓
Trainer trong 24h:
  1. Clone branch
  2. Run scripts/verify-day-{N}.sh
  3. Check artifact URLs (PR, dashboard, report)
  4. Apply rubric — assign Level 1-4 per criterion
  5. Compose feedback (Slack DM):
     ✅ Strengths (specific)
     ⚠️ Improvements (specific)
     📚 Resources to read
       ↓
You receive DM với rubric + feedback
       ↓
(Optional) Resubmit 1 lần trong 24h sau feedback
       ↓
Final score recorded
```

### Trainer feedback template

Bạn sẽ nhận DM dạng:

```
Day {N} Feedback — <Your Name>

Score: X/MAX (Level Y)

✅ Strengths:
- Specific thing 1
- Specific thing 2

⚠️ Improvements needed:
- Specific thing 1 (resource: <link>)
- Specific thing 2

📚 Recommended reading:
- <doc link>

Resubmit deadline (if applicable): 2026-05-20 23:59
```

---

## Late submission policy

| Delay | Credit | When acceptable |
|---|---|---|
| Same day | 100% | Always |
| +0-24h | 80% | OK with brief reason |
| +24-48h | 60% | Genuine effort + reason |
| > 48h | 0% | Only with documented emergency |

**Exceptions** (no penalty):
- Medical emergency (DM trainer ASAP)
- Family emergency
- Trainer technical issue (rare — verify)

**Bad excuses** (no credit):
- "Bận work" (we know — that's why module is 7 days, not 7 weeks)
- "Quên" (alarms exist)

---

## Resubmit policy

After trainer return rubric, you have **24h** to resubmit if:
- Trainer noted critical missing piece
- You disagree with grading (gather evidence)

Resubmit **once only** — final score after that.

Pattern:
```
1. Read feedback carefully
2. DM trainer with clarifying questions (if any)
3. Fix specific issues
4. Re-submit Slack #day{N}-submissions với note "RESUBMIT v2"
5. Trainer re-grades within 24h
```

---

## Self-eval — chấm chính mình

Mỗi Day, sau khi submit, tự đánh giá:

| Aspect | Question |
|---|---|
| **Functional** | Tất cả Must-have ✓? |
| **Non-functional** | Code quality ổn (ruff/lint pass)? |
| **AI workflow** | Prompt log có quality (constraint-first, explain why)? |
| **Understanding** | Tôi giải thích được tại sao chọn cách này không? |
| **Q&A readiness** | Trainer/peer hỏi 3 câu, tôi trả lời nature được? |

Self-eval Level:
- L1 (0-40%): Code chạy nhưng không hiểu
- L2 (41-60%): Hiểu phần lớn, missing some pieces
- L3 (61-80%): Solid, ready to defend
- L4 (81-100%): Excellence, can teach others

So với trainer feedback → calibrate cho Day tiếp theo.

---

## Communication Etiquette

### Slack channels

| Channel | Use |
|---|---|
| `#general` | Greetings, non-urgent |
| `#announcements` | Trainer-only |
| `#help` | Setup / general questions |
| `#day-{N}-help` | Lab-specific questions |
| `#day-{N}-submissions` | Submit artifacts |
| `#day-{N}-feedback` | Trainer DMs duplicated here for transparency |
| `#bug-report` | Bugs in starter repo (helps cohort sau) |
| `#career` | Post-course career questions |

### When DM vs Channel

| | DM Trainer | Channel |
|---|---|---|
| Grading dispute | ✅ | ❌ |
| "How do I X?" | ❌ | ✅ (help others learn) |
| Personal/sensitive | ✅ | ❌ |
| Bug found | ❌ | ✅ (#bug-report) |
| Insight worth sharing | ❌ | ✅ |

### Response time

| | Expected |
|---|---|
| Channel @here | Other students 1-4h |
| DM Trainer (urgent) | Within 24h business hours |
| DM Trainer (rubric feedback) | Within 24h after submit |
| Channel @general | Best effort, no SLA |

---

## Edge cases

### "Tôi thiếu prerequisite (Day N-1) — Day N có nên làm không?"

YES — luôn cố làm Day N, đừng skip.

```
Even with partial Day N-1, Day N artifact vẫn chấm độc lập.
Daily Checkpoint (18%) tính theo cumulative: 5/7 đạt = pass.
Bỏ Day N = giảm 1/7 chứ không phải fail toàn module.
```

### "Tôi có ý tưởng feature thêm — có nên implement không?"

OK với pattern "Must-have first, Nice-to-have after":

1. Hoàn thiện Must-have theo spec.
2. Verify pass `scripts/verify-day-N.sh`.
3. Submit.
4. **THEN** thêm Nice-to-have nếu còn thời gian.

Anti-pattern: bắt đầu với "tôi muốn build thêm X" rồi quên Must-have.

### "Tôi đang dùng public repo — có an toàn không?"

```bash
# Verify NO secrets in commits
git log --all -p | grep -iE "sk-ant-|aws_secret|password|token=" | head

# Setup pre-commit hook (recommended)
pip install pre-commit
cat > .pre-commit-config.yaml <<EOF
repos:
- repo: https://github.com/Yelp/detect-secrets
  rev: v1.5.0
  hooks:
  - id: detect-secrets
EOF
pre-commit install
```

### "Mentor không reply DM trong 24h — làm gì?"

- Check spam folder Slack
- Re-DM nhẹ nhàng: "Sếp ơi, em ping lại để confirm message đã đến"
- Hoặc post `#help` (peer có thể trả lời)
- Trong case khẩn cấp: emergency contact info trong README

---

## Tips từ alumni cohort trước

1. **Đêm trước Day N: đọc full pre-reading + skim lab guide.** Không đọc = vào lab confuse, không theo kịp.

2. **Trong lab, follow mentor demo CHẶT.** Bạn có thể custom sau, không phải lúc demo.

3. **`/cost` thường xuyên trong Claude Code session.** Cost vọt là warning sớm.

4. **AI prompt log: viết NGAY sau session.** Để 24h sau viết = quên.

5. **Submit sớm, sửa sau OK.** Better 80% credit on time hơn 100% credit late.

6. **Đừng so sánh với bạn cùng lớp.** Solo tracks = chất lượng cá nhân, không phải tốc độ.

7. **Day 6 là buổi đắt giá nhất.** Đừng skip dù Day 5 chưa xong — security debt tích lũy.

8. **Day 7 không phải thi.** Trainer chấm xong trước Day 7. Day 7 = ăn mừng + peer learn.

9. **Sau khoá: pick 1 trong 4 roadmaps.** Đừng dàn trải.

10. **Continue practicing.** 3 tháng không dùng AI workflow = quên hết.

---

*Daily Workflow v3.0 · InsightHub Running Project · Module 7 AI-Native DevOps*
