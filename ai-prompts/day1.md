# Day 1 AI Prompts

## Prompt 1 — Refine CLAUDE.md for Day 1

**Tool**: Claude Code (Sonnet 4.6)
**Time**: Day 1 setup phase

**Prompt**:
Refine the existing CLAUDE.md template for Day 1.

Goals:

* keep the file concise and practical
* optimize for Claude Code usage
* avoid generic boilerplate
* preserve the existing structure
* improve constraints and architecture notes
* add practical backend/devops conventions
* keep under 200 lines

Focus especially on:

* async ingestion refactor context
* Redis + ARQ worker architecture
* API contract preservation
* idempotent worker processing
* structured logging
* retry-safe processing
* docker-compose workflow

Do NOT:

* rewrite the entire file unnecessarily
* add enterprise-style generic text
* add vague best practices
* add frontend-heavy guidance

Please:

1. suggest edits section-by-section
2. explain WHY each addition helps the AI agent
3. keep the output concise

**Why it worked**:

* Refine existing template thay vì regenerate toàn bộ repo context
* Constraint-first prompting giúp AI tránh boilerplate
* Section-by-section review tạo human approval gate

**What I changed**:

* Rejected overly implementation-specific suggestions
* Kept only stable operational constraints
* Manually simplified wording for long-term maintainability

---

## Prompt 2 — Analyze current ingestion flow

**Tool**: Claude Code (Sonnet 4.6)
**Time**: Before implementation

**Prompt**:
Analyze ONLY the backend upload-to-ingestion flow.

Read only:

* api/app/routers/
* api/app/services/ingestion.py
* docker-compose.yml

Do NOT scan:

* web/
* tests/
* infra/
* node_modules/
* package-lock files

Goal:
identify how to refactor synchronous ingestion into Redis + ARQ worker.

Return ONLY:

1. involved files
2. current sync flow
3. minimal async refactor plan

Do not implement.
Keep answer concise.

**Why it worked**:

* Scoped exploration reduced token waste and analysis time
* Forced AI to reverse-engineer actual code instead of hallucinating architecture
* PLAN-first workflow enabled manual architecture review before editing

**What I changed**:

* Rejected adding unnecessary abstractions
* Rejected over-engineered retry systems
* Approved minimal migration strategy reusing existing ingestion logic

---

## Prompt 3 — Minimal async migration implementation

**Tool**: Claude Code (Sonnet 4.6)
**Time**: Implementation phase

**Prompt**:
Revise Step 2 with minimal logic changes.

Important:
Do NOT invent new ingestion/business logic.
Reuse the existing ingestion logic as much as possible.

Goal:
Move the existing synchronous ingestion execution out of the API request path and into the ARQ worker.

Scope:

* Keep existing extract/chunk/embed/store logic unchanged unless absolutely required for async execution.
* API should only:

  * create the document record
  * enqueue the job
  * return 202
* Worker should call the existing ingestion function or a minimally adapted version of it.
* Add only the smallest necessary retry-safe idempotency guard if retries can duplicate chunks.
* Prefer the simplest idempotency approach.
* Avoid introducing new tables or complex deduplication systems.
* Prefer modifying existing modules over creating many new abstraction layers.
* Do not modify DB schema.
* Do not modify frontend.

Before editing:

1. identify the exact existing function(s) to reuse
2. identify the minimal code movement/adaptation needed
3. explain what logic remains unchanged

Then implement only that minimal migration.
Stop after editing and list changed files.

**Why it worked**:

* Explicitly constrained AI from rewriting business logic
* Emphasized execution migration instead of architectural redesign
* Prevented unnecessary abstractions and schema changes

**What I changed**:

* Reviewed changed files before continuing
* Verified runtime behavior manually with docker compose logs
* Stopped implementation after core async flow worked successfully
