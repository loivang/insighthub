# InsightHub Day 4 Observability

Local Day 4 setup uses minikube plus kube-prometheus-stack.

## Artifacts

- `servicemonitor.yaml`: scrape InsightHub API `/metrics`
- `prometheus-rules.yaml`: latency, error burst, and ingestion backlog anomaly rules
- `grafana-dashboards/insighthub-overview.json`: Grafana dashboard
- `alerting/alertmanager-slack-example.yaml`: Slack route example
- `rca-reports/incident-1.json`: executed local RCA report
- `mlops-overview-notes.md`: MLOps overview notes

## Local Setup

```bash
bash scripts/day4-deploy-local-api.sh
bash scripts/day4-local-setup.sh
bash scripts/day4-smoke.sh
bash scripts/day4-port-forward.sh
bash scripts/day4-port-forward-app.sh
```

Open:

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001
- InsightHub web: http://localhost:3000
- InsightHub API: http://localhost:8000

Default Grafana credentials for kube-prometheus-stack are usually
`admin/prom-operator`.

## Expected App Labels

The ServiceMonitor expects the InsightHub API Service to be in namespace
`insighthub-loivang`, have label `app=insighthub`, expose port name `http`, and
serve metrics at `/metrics`.

The local deploy script starts the full Day 4 stack in minikube:

- `postgres`
- `redis`
- `insighthub-api`
- `insighthub-worker`
- `insighthub-web`

Only the API Service uses label `app=insighthub` so Prometheus scrapes the API
`/metrics` endpoint without trying to scrape the web or worker containers.

## Evidence To Submit

- Prometheus targets screenshot
- Grafana dashboard screenshot
- Prometheus alerts/rules screenshot
- RCA report files
- MLOps notes

## Optional Incident Drills

Two additional drills can be executed later if more RCA evidence is required:

- API latency spike: generate sustained `/chat` or `/documents` traffic and
  watch `InsightHubAPILatencyAnomaly`.
- Ingestion backlog: scale `insighthub-worker` to 0 replicas, upload documents,
  and watch `InsightHubIngestionBacklog`.
