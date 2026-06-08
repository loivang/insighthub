#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-insighthub-loivang}"

echo "InsightHub web: http://localhost:3000"
echo "InsightHub API: http://localhost:8000"
echo "Press Ctrl+C to stop port-forwarding."

kubectl -n "${NAMESPACE}" port-forward svc/insighthub-web 3000:3000 &
WEB_PID=$!

kubectl -n "${NAMESPACE}" port-forward svc/insighthub-api 8000:8000 &
API_PID=$!

trap 'kill ${WEB_PID} ${API_PID} 2>/dev/null || true' EXIT
wait
