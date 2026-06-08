#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-insighthub-loivang}"

kubectl config use-context minikube

echo "Building API image inside minikube..."
minikube image build -t insighthub-api:day4 ./api

echo "Building worker image inside minikube..."
minikube image build -t insighthub-worker:day4 -f ingestion-worker/Dockerfile .

echo "Building web image inside minikube..."
minikube image build -t insighthub-web:day4 ./web

echo "Applying local web/API/worker/Postgres/Redis manifests..."
kubectl apply -f k8s/local/insighthub-api-observability.yaml

echo "Waiting for local InsightHub stack..."
kubectl -n "${NAMESPACE}" rollout status deployment/postgres --timeout=180s
kubectl -n "${NAMESPACE}" rollout status deployment/redis --timeout=180s
kubectl -n "${NAMESPACE}" rollout status deployment/insighthub-api --timeout=180s
kubectl -n "${NAMESPACE}" rollout status deployment/insighthub-worker --timeout=180s
kubectl -n "${NAMESPACE}" rollout status deployment/insighthub-web --timeout=180s

echo "Local InsightHub stack is deployed for Day 4 metrics."
kubectl -n "${NAMESPACE}" get pods,svc,endpoints
