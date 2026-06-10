# Day 6 Security, Governance & FinOps

Day 6 secures InsightHub's LLM path and adds cost controls.

## Artifacts

- `promptfooconfig.yaml`: Promptfoo red-team config with required OWASP-style plugins.
- `guardrails.yaml`: local guardrail policy used by the API implementation.
- `litellm-config.yaml`: LiteLLM Gateway model routing config.
- `litellm-virtual-keys.json`: 3 virtual key budget definitions.
- `sample-docs/poisoned-policy.md`: indirect prompt injection sample.
- `reports/initial-red-team-report.md`: baseline risk notes before controls.
- `reports/final-red-team-report.md`: implemented-control mapping after fixes.
- `red-team-report.html`: placeholder/export target; Promptfoo scan has not been
  run yet in this local environment.
- `threat-model.md`: 6+ threats and mitigations.
- `../observability/grafana-dashboards/llm-cost.json`: LLM cost dashboard.

## Local LiteLLM

```bash
docker compose --profile day6 up -d litellm-db litellm
curl -H "Authorization: Bearer ${LITELLM_MASTER_KEY:-sk-insighthub-master-local}" \
  http://localhost:4000/health
```

Create local virtual keys:

```bash
bash scripts/day6-create-litellm-keys.sh
```

Route InsightHub generation through the gateway:

```bash
LLM_PROVIDER=litellm
LITELLM_BASE_URL=http://litellm:4000
LITELLM_API_KEY=<token returned for the insighthub-api virtual key>
LITELLM_CHAT_MODEL=insighthub-chat
```

## Promptfoo

```bash
promptfoo redteam generate -c security/promptfooconfig.yaml
promptfoo redteam run -c security/promptfooconfig.yaml
```

Export the final HTML report to:

```text
security/red-team-report.html
```

Current status: Promptfoo scan is prepared but not yet executed. The config,
plugins, poisoned sample document, and guardrail fixes are committed so the scan
can be run later when the API and provider key are available.

## AWS Budget Evidence

AWS is only needed for the account-level budget alert evidence:

```bash
export BUDGET_ALERT_EMAIL=you@example.com
bash scripts/day6-create-aws-budget.sh
aws budgets describe-budget \
  --account-id "$(aws sts get-caller-identity --query Account --output text)" \
  --budget-name insighthub-llm-monthly
```

## Verify

```bash
bash scripts/verify-day-6-local.sh
```
