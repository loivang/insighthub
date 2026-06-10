# Initial Red-Team Report

Date: 2026-06-10

Scope:

- Target: InsightHub `/chat`
- Tooling: Promptfoo red-team config in `security/promptfooconfig.yaml`
- Plugins: prompt-injection, indirect-prompt-injection, rag-poisoning, pii, excessive-agency

Expected baseline risks before Day 6 controls:

| Severity | Risk | Evidence source | Fix |
|---|---|---|---|
| HIGH | Indirect prompt injection in uploaded document text | `security/sample-docs/poisoned-policy.md` contains a hidden malicious instruction | Harden system prompt and sanitize retrieved chunks |
| HIGH | Prompt injection in user question | Promptfoo config includes direct injection tests | Sanitize user question before provider call |
| MEDIUM | PII leakage risk | Promptfoo config includes PII tests | Add basic PII redaction |
| MEDIUM | Budget exhaustion risk | Direct provider calls have no per-service cap | Route via LiteLLM virtual keys |

Status:

- This is a baseline risk note, not a completed Promptfoo scan export.
- Promptfoo has not been run yet in this local environment.
- Run Promptfoo against a live API/provider key to produce the real initial scan
  report if the trainer requires raw tool output.
