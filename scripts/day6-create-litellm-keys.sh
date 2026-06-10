#!/usr/bin/env bash
set -euo pipefail

LITELLM_URL="${LITELLM_URL:-http://localhost:4000}"
LITELLM_MASTER_KEY="${LITELLM_MASTER_KEY:-sk-insighthub-master-local}"

create_key() {
  local alias="$1"
  local models="$2"
  local budget="$3"

  curl -sS -X POST "${LITELLM_URL}/key/generate" \
    -H "Authorization: Bearer ${LITELLM_MASTER_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
      \"key_alias\": \"${alias}\",
      \"models\": ${models},
      \"max_budget\": ${budget},
      \"budget_duration\": \"30d\"
    }"
  echo
}

create_key "insighthub-api" '["insighthub-chat"]' 3
create_key "chatops-bot" '["insighthub-chat"]' 1
create_key "developer" '["insighthub-chat","insighthub-claude","insighthub-openai"]' 1
