#!/usr/bin/env bash
set -euo pipefail

MONITORING_NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"
RELEASE="${RELEASE:-kube-prometheus-stack}"

GRAFANA_SERVICE="${GRAFANA_SERVICE:-${RELEASE}-grafana}"
PROMETHEUS_SERVICE="${PROMETHEUS_SERVICE:-prometheus-operated}"

echo "Waiting for monitoring pods to become ready..."
kubectl -n "${MONITORING_NAMESPACE}" wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=grafana \
  --timeout=180s || true
kubectl -n "${MONITORING_NAMESPACE}" wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=prometheus \
  --timeout=180s || true

if ! kubectl -n "${MONITORING_NAMESPACE}" get svc "${GRAFANA_SERVICE}" >/dev/null 2>&1; then
  GRAFANA_SERVICE="$(kubectl -n "${MONITORING_NAMESPACE}" get svc -o name | grep grafana | head -n 1 | cut -d/ -f2)"
fi

if ! kubectl -n "${MONITORING_NAMESPACE}" get svc "${PROMETHEUS_SERVICE}" >/dev/null 2>&1; then
  PROMETHEUS_SERVICE="$(kubectl -n "${MONITORING_NAMESPACE}" get svc -o name | grep prometheus | grep -v kube-state | grep -v node-exporter | head -n 1 | cut -d/ -f2)"
fi

echo "Grafana:    http://localhost:3001"
echo "Prometheus: http://localhost:9090"
echo "Grafana service: ${GRAFANA_SERVICE}"
echo "Prometheus service: ${PROMETHEUS_SERVICE}"
echo "Press Ctrl+C to stop port-forwarding."

kubectl -n "${MONITORING_NAMESPACE}" port-forward "svc/${GRAFANA_SERVICE}" 3001:80 &
GRAFANA_PID=$!

kubectl -n "${MONITORING_NAMESPACE}" port-forward "svc/${PROMETHEUS_SERVICE}" 9090:9090 &
PROM_PID=$!

trap 'kill ${GRAFANA_PID} ${PROM_PID} 2>/dev/null || true' EXIT
wait
