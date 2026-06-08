from __future__ import annotations

import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path

from app import commands


AUDIT_LOG = Path(os.getenv("CHATOPS_AUDIT_LOG", "audit-log.jsonl"))


def _audit(command: str, result: str) -> None:
    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "source": "cli",
        "user": os.getenv("USER", "local"),
        "command": command,
        "result": result[:500],
    }
    with AUDIT_LOG.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(entry) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description="InsightHub ChatOps CLI")
    parser.add_argument(
        "command",
        choices=["status", "alerts", "metrics", "diagnose", "diagnosis", "rca"],
        help="Command to run",
    )
    parser.add_argument("args", nargs="*")
    args = parser.parse_args()

    if args.command == "status":
        output = commands.status()
    elif args.command == "alerts":
        output = commands.alerts()
    elif args.command == "metrics":
        output = commands.metrics()
    else:
        output = commands.diagnosis()

    _audit(" ".join([args.command, *args.args]).strip(), output)
    print(output)


if __name__ == "__main__":
    main()
