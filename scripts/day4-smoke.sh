#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-insighthub-loivang}"
MONITORING_NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"

echo "== Context =="
kubectl config current-context

echo
echo "== Namespaces =="
kubectl get namespace "${NAMESPACE}"
kubectl get namespace "${MONITORING_NAMESPACE}"

echo
echo "== Monitoring pods =="
kubectl get pods -n "${MONITORING_NAMESPACE}"

echo
echo "== ServiceMonitor =="
kubectl get servicemonitor -n "${NAMESPACE}" insighthub-service-monitor

echo
echo "== InsightHub API target service =="
kubectl get svc -n "${NAMESPACE}" insighthub-api --show-labels
kubectl get endpoints -n "${NAMESPACE}" insighthub-api

echo
echo "== InsightHub local stack =="
kubectl get deployment -n "${NAMESPACE}" postgres redis insighthub-api insighthub-worker insighthub-web
kubectl get svc -n "${NAMESPACE}" postgres redis insighthub-api insighthub-web --show-labels

echo
echo "== PrometheusRule =="
kubectl get prometheusrule -n "${MONITORING_NAMESPACE}" insighthub-anomaly-rules

echo
echo "Day 4 local smoke checks completed."
