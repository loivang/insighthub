from __future__ import annotations

import json
import os
import urllib.parse
import urllib.request

from app.clients.diagnosis import diagnose, format_diagnosis


API_URL = os.getenv("INSIGHTHUB_API_URL", "http://localhost:8000").rstrip("/")
PROMETHEUS_URL = os.getenv("PROMETHEUS_URL", "http://localhost:9090").rstrip("/")


def _get_json(url: str, timeout: float = 3.0) -> dict:
    try:
        with urllib.request.urlopen(url, timeout=timeout) as response:
            return {"status_code": response.status, "body": json.loads(response.read().decode("utf-8"))}
    except Exception as error:
        return {"status_code": 0, "error": str(error)}


def _prometheus_query(expr: str) -> str:
    params = urllib.parse.urlencode({"query": expr})
    result = _get_json(f"{PROMETHEUS_URL}/api/v1/query?{params}")
    try:
        series = result["body"]["data"]["result"]
    except KeyError:
        return "Prometheus query failed."
    if not series:
        return "No data."
    lines = []
    for item in series[:8]:
        metric = item.get("metric", {})
        value = item.get("value", ["", "0"])[1]
        name = metric.get("__name__") or metric.get("job") or metric.get("service") or "result"
        lines.append(f"- {name}: {value}")
    return "\n".join(lines)


def status() -> str:
    healthz = _get_json(f"{API_URL}/healthz")
    readyz = _get_json(f"{API_URL}/readyz")
    return (
        "InsightHub status\n\n"
        f"- /healthz: {healthz.get('status_code')}\n"
        f"- /readyz: {readyz.get('status_code')}"
    )


def alerts() -> str:
    result = _get_json(f"{PROMETHEUS_URL}/api/v1/alerts")
    active = []
    for alert in result.get("body", {}).get("data", {}).get("alerts", []):
        if alert.get("state") == "firing":
            labels = alert.get("labels", {})
            active.append(f"- {labels.get('alertname', 'unknown')} severity={labels.get('severity', 'unknown')}")
    if not active:
        return "No firing Prometheus alerts."
    return "Firing Prometheus alerts\n\n" + "\n".join(active)


def metrics() -> str:
    requests = _prometheus_query("sum(rate(insighthub_http_requests_total[5m]))")
    errors = _prometheus_query('sum(rate(insighthub_http_requests_total{status=~"5.."}[5m]))')
    return f"InsightHub metrics\n\nRequest rate:\n{requests}\n\n5xx rate:\n{errors}"


def rca(_incident_id: str | None = None) -> str:
    return diagnosis()


def diagnosis() -> str:
    return format_diagnosis(diagnose())


def help_text() -> str:
    return (
        "InsightHub ChatOps commands\n\n"
        "- status: check API health/readiness\n"
        "- alerts: show firing Prometheus alerts\n"
        "- metrics: show request and 5xx rates\n"
        "- diagnose: infer likely root cause from live signals\n"
        "- rca: alias for diagnose"
    )
