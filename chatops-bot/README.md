# InsightHub ChatOps Bot

Minimal Day 5 ChatOps bot for local lab use.

The bot can run from CLI or Slack Socket Mode. It reads live signals from the
local InsightHub stack, Prometheus, and Kubernetes, then returns a short
operational summary.

## Setup

```bash
cd chatops-bot
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

Expected local endpoints:

```bash
export INSIGHTHUB_API_URL=http://localhost:8000
export PROMETHEUS_URL=http://localhost:9090
export KUBERNETES_NAMESPACE=insighthub-loivang
```

## CLI

```bash
python -m app.main status
python -m app.main alerts
python -m app.main metrics
python -m app.main diagnose
python -m app.main rca
```

`diagnose` and `rca` are rule-based live RCA commands. They do not call an
external AI API and do not read a pre-written incident report as the main
source.

## Slack

Create a Slack app with:

- Socket Mode enabled.
- App-level token scope: `connections:write`.
- Bot token scopes: `commands`, `chat:write`, `app_mentions:read`.
- Slash command: `/insighthub`.

Run:

```bash
export SLACK_BOT_TOKEN=xoxb-...
export SLACK_APP_TOKEN=xapp-...
python -m app.slack_app
```

Slack commands:

```text
/insighthub status
/insighthub alerts
/insighthub metrics
/insighthub diagnose
/insighthub rca
```

Audit events are written to `audit-log.jsonl` by default.
