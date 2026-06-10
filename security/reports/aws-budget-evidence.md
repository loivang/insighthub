# AWS Budget Evidence

Date: 2026-06-10

Command attempted:

```bash
export BUDGET_ALERT_EMAIL=vangvanloi97@gmail.com
bash scripts/day6-create-aws-budget.sh
```

Expected budget:

- Account: `919664459382`
- Budget name: `insighthub-llm-monthly`
- Limit: `$5/month`
- Alert: actual cost greater than 80%
- Tag filter: `project=insighthub`

Actual result:

```text
AccessDeniedException: User: arn:aws:iam::919664459382:user/DE000180 is not
authorized to perform: budgets:ModifyBudget on resource:
arn:aws:budgets::919664459382:budget/insighthub-llm-monthly because no
identity-based policy allows the budgets:ModifyBudget action
```

Status:

- Script is implemented in `scripts/day6-create-aws-budget.sh`.
- Budget creation is blocked by IAM permission in the training AWS account.
- Required permission: `budgets:ModifyBudget`; recommended read permission:
  `budgets:ViewBudget`.
- LiteLLM virtual key `max_budget` remains the hard budget cap for local Day 6
  validation.
