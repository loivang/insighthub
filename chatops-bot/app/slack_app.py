from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path

from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler

from app import commands


AUDIT_LOG = Path(os.getenv("CHATOPS_AUDIT_LOG", "audit-log.jsonl"))


def _audit(user: str, command: str, result: str) -> None:
    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "source": "slack",
        "user": user,
        "command": command,
        "result": result[:500],
    }
    with AUDIT_LOG.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(entry) + "\n")


def dispatch(text: str) -> str:
    parts = text.strip().split()
    command = parts[0].lower() if parts else "help"

    if command in {"help", "-h", "--help"}:
        return commands.help_text()
    if command == "status":
        return commands.status()
    if command == "alerts":
        return commands.alerts()
    if command == "metrics":
        return commands.metrics()
    if command in {"diagnose", "diagnosis", "rca"}:
        return commands.diagnosis()

    return commands.help_text()


def main() -> None:
    bot_token = os.getenv("SLACK_BOT_TOKEN")
    app_token = os.getenv("SLACK_APP_TOKEN")
    if not bot_token or not app_token:
        raise RuntimeError("SLACK_BOT_TOKEN and SLACK_APP_TOKEN are required")

    app = App(token=bot_token)

    @app.command("/insighthub")
    def handle_insighthub(ack, command, respond):
        ack()
        text = command.get("text", "")
        user = command.get("user_name") or command.get("user_id", "unknown")
        output = dispatch(text)
        _audit(user=user, command=text or "help", result=output)
        respond(output)

    SocketModeHandler(app, app_token).start()


if __name__ == "__main__":
    main()
