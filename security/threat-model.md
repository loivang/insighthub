# InsightHub Day 6 Threat Model

## Scope

InsightHub is a RAG notebook with document upload, retrieval, LLM generation,
ChatOps access, Prometheus/Grafana observability, and LiteLLM gateway routing.

## Assets

- User documents and retrieved chunks.
- LLM provider keys and LiteLLM virtual keys.
- System prompts and guardrail configuration.
- ChatOps audit logs.
- Cost/budget data.

## Threats And Mitigations

| # | Threat | Risk | Mitigation |
|---|---|---|---|
| 1 | Prompt injection in user question | User asks the model to ignore instructions or reveal secrets | Hardened system prompt and input sanitization in `llm.py` |
| 2 | Indirect prompt injection in uploaded documents | Poisoned document chunk overrides model behavior | Treat document chunks as untrusted data and sanitize retrieved context |
| 3 | RAG poisoning | Uploaded content causes unsafe or false grounded answers | Source citation, context-only answering, Promptfoo rag-poisoning tests |
| 4 | PII leakage | Model repeats email/phone/secrets from retrieved chunks | Basic PII redaction and Promptfoo PII checks |
| 5 | Excessive agency | Chat endpoint is tricked into calling tools or executing actions | Chat endpoint has no tool execution path; ChatOps commands are explicit |
| 6 | Provider key bypass | App calls Gemini/Anthropic directly and avoids budget limits | `LLM_PROVIDER=litellm` routes generation through LiteLLM gateway |
| 7 | Budget exhaustion | High-volume requests create unexpected LLM spend | LiteLLM virtual keys with `max_budget` and AWS Budget alert |
| 8 | Prompt/system leakage | User extracts internal prompt or security rules | Guardrail patterns block prompt leakage attempts |

## Defense In Depth

1. Prompt hardening.
2. Input and retrieved-context sanitization.
3. Promptfoo red-team regression tests.
4. LiteLLM gateway for routing, audit, and budget caps.
5. Grafana cost visibility.
6. AWS Budgets as an account-level alert.

## Residual Risk

The local regex guardrails are enough for the lab baseline, but production
should add provider-native guardrails, NeMo Guardrails or Llama Guard, full
Promptfoo HTML exports, and a persistent LiteLLM database for durable budgets.
