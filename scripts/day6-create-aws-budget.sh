#!/usr/bin/env bash
set -euo pipefail

ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
BUDGET_NAME="${BUDGET_NAME:-insighthub-llm-monthly}"
LIMIT_USD="${LIMIT_USD:-5}"
EMAIL="${BUDGET_ALERT_EMAIL:?Set BUDGET_ALERT_EMAIL before running this script}"
TAG_FILTER="${BUDGET_TAG_FILTER:-user:project\$insighthub}"

tmp_budget="$(mktemp)"
tmp_notifications="$(mktemp)"
trap 'rm -f "$tmp_budget" "$tmp_notifications"' EXIT

cat >"$tmp_budget" <<JSON
{
  "BudgetName": "${BUDGET_NAME}",
  "BudgetLimit": {
    "Amount": "${LIMIT_USD}",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST",
  "CostFilters": {
    "TagKeyValue": [
      "${TAG_FILTER}"
    ]
  }
}
JSON

cat >"$tmp_notifications" <<JSON
[
  {
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [
      {
        "SubscriptionType": "EMAIL",
        "Address": "${EMAIL}"
      }
    ]
  }
]
JSON

aws budgets create-budget \
  --account-id "$ACCOUNT_ID" \
  --budget "file://$tmp_budget" \
  --notifications-with-subscribers "file://$tmp_notifications"

aws budgets describe-budget \
  --account-id "$ACCOUNT_ID" \
  --budget-name "$BUDGET_NAME"
