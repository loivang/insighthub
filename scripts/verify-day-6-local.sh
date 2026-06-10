#!/usr/bin/env bash
set -euo pipefail

pass() {
  printf 'PASS %s\n' "$1"
}

fail() {
  printf 'FAIL %s\n' "$1"
  exit 1
}

require_file() {
  test -f "$1" && pass "$1 exists" || fail "$1 missing"
}

require_file security/promptfooconfig.yaml
require_file security/guardrails.yaml
require_file security/litellm-config.yaml
require_file security/litellm-virtual-keys.json
require_file security/red-team-report.html
require_file security/threat-model.md
require_file security/cost-report.md
require_file observability/grafana-dashboards/llm-cost.json
require_file scripts/day6-create-litellm-keys.sh
require_file scripts/day6-create-aws-budget.sh

grep -q "prompt-injection" security/promptfooconfig.yaml || fail "prompt-injection plugin missing"
grep -q "indirect-prompt-injection" security/promptfooconfig.yaml || fail "indirect-prompt-injection plugin missing"
grep -q "rag-poisoning" security/promptfooconfig.yaml || fail "rag-poisoning plugin missing"
grep -q "pii" security/promptfooconfig.yaml || fail "pii plugin missing"
grep -q "excessive-agency" security/promptfooconfig.yaml || fail "excessive-agency plugin missing"
pass "Promptfoo required plugins present"

grep -q "LITELLM_BASE_URL" .env.example || fail "LiteLLM base URL env example missing"
grep -q "LITELLM_API_KEY" .env.example || fail "LiteLLM API key env example missing"
grep -q "provider == \"litellm\"" api/app/services/llm.py || fail "API LiteLLM provider missing"
grep -q "LITELLM_API_KEY" docker-compose.yml || fail "Compose LiteLLM env missing"
pass "InsightHub can route through LiteLLM"

threat_count="$(grep -c '^| [0-9]' security/threat-model.md || true)"
if [ "$threat_count" -lt 6 ]; then
  fail "threat model has fewer than 6 threats"
fi
pass "Threat model has ${threat_count} threats"

key_count="$(grep -c '"key_alias"' security/litellm-virtual-keys.json || true)"
if [ "$key_count" -lt 3 ]; then
  fail "fewer than 3 LiteLLM virtual keys documented"
fi
pass "LiteLLM virtual key budget definitions present"

if curl -fsS -H "Authorization: Bearer ${LITELLM_MASTER_KEY:-sk-insighthub-master-local}" http://localhost:4000/health >/dev/null 2>&1; then
  pass "LiteLLM health endpoint is reachable"
else
  printf 'WARN LiteLLM is not running locally; start it with: docker compose --profile day6 up -d litellm-db litellm\n'
fi

printf '\nDay 6 local artifact verification complete.\n'
