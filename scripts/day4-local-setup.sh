#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-insighthub-loivang}"
MONITORING_NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"
RELEASE="${RELEASE:-kube-prometheus-stack}"

kubectl config use-context minikube

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace "${MONITORING_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null
helm repo update >/dev/null

helm upgrade --install "${RELEASE}" prometheus-community/kube-prometheus-stack \
  -n "${MONITORING_NAMESPACE}" \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.serviceMonitorNamespaceSelector.any=true \
  --set prometheus.prometheusSpec.ruleNamespaceSelector.any=true

kubectl apply -f observability/servicemonitor.yaml
kubectl apply -f observability/prometheus-rules.yaml

cat <<EOF
Day 4 local monitoring setup applied.

Next:
  bash scripts/day4-smoke.sh
  bash scripts/day4-port-forward.sh
EOF
