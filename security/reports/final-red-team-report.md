# Final Red-Team Report

Date: 2026-06-10

Applied fixes:

- Hardened RAG system prompt in `api/app/services/llm.py`.
- Sanitized user question and retrieved document chunks before LLM calls.
- Added basic PII redaction for email and Vietnam phone patterns.
- Added LiteLLM Gateway routing with virtual key budget definitions.
- Added local guardrails documentation in `security/guardrails.yaml`.

Implemented-control mapping:

| Check | Result |
|---|---|
| prompt-injection | Covered by hardened prompt and question sanitization |
| indirect-prompt-injection | Covered by retrieved context sanitization |
| rag-poisoning | Covered by untrusted-document rule and Promptfoo config |
| pii | Covered by basic email/phone redaction |
| excessive-agency | Covered because `/chat` exposes no tool execution path |

Residual risk:

- Local regex guardrails are intentionally lightweight for the lab.
- A production system should add provider-native guardrails or NeMo/Llama Guard
  and export the Promptfoo HTML report from a real scan run.

Status:

- No known HIGH/CRITICAL scenarios remain intentionally unaddressed in the
  implemented controls.
- Promptfoo has not been run yet in this local environment.
- If Promptfoo is run against live provider keys, export the generated HTML
  report to `security/red-team-report.html`.
- This markdown file is not a substitute for raw Promptfoo output if the trainer
  explicitly asks for scan logs.
