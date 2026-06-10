# InsightHub LLM Cost Report

Period: Day 6 lab baseline

## Budget Target

| Scope | Weekly target | Monthly cap |
|---|---:|---:|
| InsightHub API | < $3/week | $3 virtual key cap |
| ChatOps bot | < $1/week | $1 virtual key cap |
| Developer testing | < $1/week | $1 virtual key cap |

Total Day 6 target: **< $5/week**.

## Controls

- InsightHub generation can route through LiteLLM with `LLM_PROVIDER=litellm`.
- LiteLLM virtual keys are defined in `security/litellm-virtual-keys.json`.
- AWS account alert script creates `insighthub-llm-monthly` budget.
- Grafana dashboard `observability/grafana-dashboards/llm-cost.json` tracks spend,
  request rate, token rate, and spend by virtual key.

## AWS Budgets Evidence

Budget script:

```bash
bash scripts/day6-create-aws-budget.sh
```

Current training account result:

```text
AccessDeniedException: User arn:aws:iam::919664459382:user/DE000180 is not
authorized to perform budgets:ModifyBudget on
arn:aws:budgets::919664459382:budget/insighthub-llm-monthly.
```

Interpretation:

- The Day 6 AWS Budgets script is implemented.
- The training IAM user does not currently have permission to create or update
  AWS Budgets.
- Hard budget control is still represented locally by LiteLLM virtual key
  `max_budget` definitions.
- AWS Budget creation can be completed after trainer/admin grants
  `budgets:ModifyBudget` / `budgets:ViewBudget` permission.

## Local Lab Estimate

For local validation, the default `.env.example` keeps provider keys empty, so
InsightHub falls back to extractive answers and creates no provider spend.

Expected lab spend before real Promptfoo/API-key runs: **$0.00**.

When running Promptfoo against a real provider, use the LiteLLM virtual key caps
and reduce `redteam.numTests` if rate limit or cost is too high.

Promptfoo has not been run yet in this local environment, so there is no
Promptfoo-generated provider spend to report.
