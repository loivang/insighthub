# Day 6 AI Prompts

## Prompt 1 - Analyze Day 6 Requirements

**Tool**: Codex
**Time**: 2026-06-10

**Prompt**:
Phân tích yêu cầu Day 6, xác định mục tiêu học, điều kiện pass, và AWS có cần
thiết không.

**Why it worked**:
- Forced the agent to read the real project specification before implementing.
- Separated Security, Governance, and FinOps artifacts.

**What I changed**:
- Chose local-first LiteLLM and Promptfoo artifacts.
- Kept AWS only for Budgets evidence.

## Prompt 2 - Implement LiteLLM Gateway

**Tool**: Codex
**Time**: 2026-06-10

**Prompt**:
Implement Day 6 with LiteLLM gateway, provider routing, guardrails, Promptfoo,
threat model, cost dashboard, and AWS budget script.

**Why it worked**:
- Scoped the implementation to Day 6 must-have artifacts.
- Avoided replacing existing Gemini/Anthropic/Ollama providers.

**What I changed**:
- Added `LLM_PROVIDER=litellm`.
- Added local LiteLLM config and virtual key budget definitions.

## Prompt 3 - Keep It Lab-Sized

**Tool**: Codex
**Time**: 2026-06-10

**Prompt**:
Keep the solution just enough to pass the lab and avoid unnecessary AWS/EKS
work unless the spec explicitly requires it.

**Why it worked**:
- Preserved the existing local workflow.
- Made AWS Budgets a focused evidence step instead of a full cloud deployment.

**What I changed**:
- Added local verification script.
- Documented residual production risks instead of overbuilding them.
