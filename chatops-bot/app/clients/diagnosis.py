from __future__ import annotations

import json
import os
import subprocess
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass


API_URL = os.getenv("INSIGHTHUB_API_URL", "http://localhost:8000").rstrip("/")
PROMETHEUS_URL = os.getenv("PROMETHEUS_URL", "http://localhost:9090").rstrip("/")
NAMESPACE = os.getenv("KUBERNETES_NAMESPACE", "insighthub-loivang")


@dataclass
class Diagnosis:
    impact: str
    evidence: list[str]
    likely_root_cause: str
    recommended_action: str


def _get_json(url: str, timeout: float = 3.0) -> dict:
    request = urllib.request.Request(url)
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            body = response.read().decode("utf-8")
            return {"status_code": response.status, "body": json.loads(body)}
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        try:
            parsed = json.loads(body)
        except json.JSONDecodeError:
            parsed = body
        return {"status_code": error.code, "body": parsed}
    except Exception as error:
        return {"status_code": 0, "error": str(error)}


def _prometheus_query(expr: str) -> float:
    params = urllib.parse.urlencode({"query": expr})
    result = _get_json(f"{PROMETHEUS_URL}/api/v1/query?{params}")
    try:
        return float(result["body"]["data"]["result"][0]["value"][1])
    except (KeyError, IndexError, TypeError, ValueError):
        return 0.0


def _prometheus_alerts() -> list[str]:
    result = _get_json(f"{PROMETHEUS_URL}/api/v1/alerts")
    alerts = result.get("body", {}).get("data", {}).get("alerts", [])
    names = []
    for alert in alerts:
        if alert.get("state") == "firing":
            names.append(alert.get("labels", {}).get("alertname", "unknown"))
    return sorted(set(names))


def _kubectl_pods() -> list[dict]:
    command = ["kubectl", "get", "pods", "-n", NAMESPACE, "-o", "json"]
    try:
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
        )
    except Exception as error:
        return [{"name": "kubectl", "phase": "unknown", "reason": str(error), "ready": "0/0"}]

    if completed.returncode != 0:
        return [
            {
                "name": "kubectl",
                "phase": "unknown",
                "reason": completed.stderr.strip() or completed.stdout.strip(),
                "ready": "0/0",
            }
        ]

    data = json.loads(completed.stdout)
    pods = []
    for item in data.get("items", []):
        statuses = item.get("status", {}).get("containerStatuses", [])
        ready_count = sum(1 for status in statuses if status.get("ready"))
        total_count = len(statuses)
        reasons = []
        for status in statuses:
            state = status.get("state", {})
            for value in state.values():
                reason = value.get("reason")
                if reason:
                    reasons.append(reason)
        pods.append(
            {
                "name": item.get("metadata", {}).get("name", "unknown"),
                "phase": item.get("status", {}).get("phase", "unknown"),
                "ready": f"{ready_count}/{total_count}",
                "reason": ",".join(reasons),
            }
        )
    return pods


def _matching_pods(pods: list[dict], service: str) -> list[str]:
    matches = []
    for pod in pods:
        name = pod["name"]
        text = f"{name} {pod['phase']} {pod['ready']} {pod['reason']}".lower()
        unhealthy = pod["phase"] != "Running" or not pod["ready"].startswith(pod["ready"].split("/")[-1])
        if service in name.lower() and unhealthy:
            matches.append(f"{name} phase={pod['phase']} ready={pod['ready']} reason={pod['reason'] or 'n/a'}")
        elif service in text and any(token in text for token in ("pending", "crashloop", "error", "failed")):
            matches.append(f"{name} phase={pod['phase']} ready={pod['ready']} reason={pod['reason'] or 'n/a'}")
    return matches


def diagnose() -> Diagnosis:
    evidence: list[str] = []
    readyz = _get_json(f"{API_URL}/readyz")
    healthz = _get_json(f"{API_URL}/healthz")
    pods = _kubectl_pods()
    firing_alerts = _prometheus_alerts()
    five_xx_rate = _prometheus_query('sum(rate(insighthub_http_requests_total{status=~"5.."}[5m]))')

    readyz_ok = readyz.get("status_code") == 200
    healthz_ok = healthz.get("status_code") == 200
    evidence.append(f"API /readyz status: {readyz.get('status_code')}")
    evidence.append(f"API /healthz status: {healthz.get('status_code')}")

    postgres_issues = _matching_pods(pods, "postgres")
    redis_issues = _matching_pods(pods, "redis")
    api_issues = _matching_pods(pods, "api")
    worker_issues = _matching_pods(pods, "worker")

    if postgres_issues:
        evidence.append("Postgres pod issue: " + "; ".join(postgres_issues))
    if redis_issues:
        evidence.append("Redis pod issue: " + "; ".join(redis_issues))
    if api_issues:
        evidence.append("API pod issue: " + "; ".join(api_issues))
    if worker_issues:
        evidence.append("Worker pod issue: " + "; ".join(worker_issues))
    if firing_alerts:
        evidence.append("Firing alerts: " + ", ".join(firing_alerts))
    if five_xx_rate > 0:
        evidence.append(f"Recent 5xx rate: {five_xx_rate:.4f} req/s")

    if not readyz_ok and postgres_issues:
        return Diagnosis(
            impact="API readiness is degraded; user requests that need the database may fail.",
            evidence=evidence,
            likely_root_cause="Postgres is unavailable or not ready.",
            recommended_action="Restore Postgres, wait until the pod is Ready, then verify /readyz returns 200.",
        )
    if not readyz_ok and redis_issues:
        return Diagnosis(
            impact="API readiness or ingestion flow is degraded.",
            evidence=evidence,
            likely_root_cause="Redis is unavailable or not ready.",
            recommended_action="Restore Redis, then verify document ingestion and worker processing.",
        )
    if not healthz_ok or api_issues:
        return Diagnosis(
            impact="API availability is degraded.",
            evidence=evidence,
            likely_root_cause="The API pod or process is unhealthy.",
            recommended_action="Inspect API pod logs and rollout status, then restart or fix the deployment.",
        )
    if worker_issues:
        return Diagnosis(
            impact="Document ingestion may be delayed.",
            evidence=evidence,
            likely_root_cause="The ingestion worker is unavailable or not ready.",
            recommended_action="Inspect worker logs and Redis connectivity, then restore the worker deployment.",
        )
    if firing_alerts:
        return Diagnosis(
            impact="Monitoring detected an active alert.",
            evidence=evidence,
            likely_root_cause="The firing Prometheus alert condition is the most likely issue.",
            recommended_action="Open Prometheus alert details and inspect the affected service logs.",
        )

    return Diagnosis(
        impact="No active user-facing degradation detected.",
        evidence=evidence,
        likely_root_cause="No obvious root cause found from API health, Kubernetes pods, and Prometheus alerts.",
        recommended_action="Continue monitoring or run a controlled incident drill to test RCA behavior.",
    )


def format_diagnosis(result: Diagnosis) -> str:
    evidence = "\n".join(f"- {item}" for item in result.evidence)
    return (
        "InsightHub diagnosis\n\n"
        f"Impact:\n{result.impact}\n\n"
        f"Evidence:\n{evidence}\n\n"
        f"Likely root cause:\n{result.likely_root_cause}\n\n"
        f"Recommended action:\n{result.recommended_action}"
    )
