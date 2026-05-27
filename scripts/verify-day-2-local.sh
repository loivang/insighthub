#!/usr/bin/env bash
# InsightHub - Verify Day 2 artifact
# Chay: bash scripts/verify-day-2-local.sh
# Muc dich: kiem tra Day 2 MCP setup dat cac yeu cau Must-have spec.

set -u

PASS=0
FAIL=0

green(){ printf "\033[32m%s\033[0m\n" "$1"; }
red(){ printf "\033[31m%s\033[0m\n" "$1"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$1"; }

ok() { green "  [PASS] $1"; PASS=$((PASS+1)); }
ng() { red "  [FAIL] $1"; FAIL=$((FAIL+1)); }
skip() { yellow "  [SKIP] $1"; }

json_query() {
  # $1 = Python expression using variable data, for environments without jq.
  python3 -c "import json; data=json.load(open('.mcp.json')); print($1)"
}

echo "=================================="
echo " InsightHub - Verify Day 2 (MCP)"
echo "=================================="
echo

# MH1-2: .mcp.json valid + >=4 servers
echo "[1] .mcp.json quality..."
if [ -f .mcp.json ]; then
  if command -v jq >/dev/null 2>&1; then
    if jq empty .mcp.json 2>/dev/null; then
      ok ".mcp.json valid JSON"
      COUNT=$(jq '.mcpServers | length' .mcp.json)
      ARGS=$(jq -r '.mcpServers[].args[]?' .mcp.json)
      FS_ARGS=$(jq -r '.mcpServers.filesystem.args[]?' .mcp.json 2>/dev/null)
    else
      ng ".mcp.json khong valid JSON"
      COUNT=0
      ARGS=""
      FS_ARGS=""
    fi
  elif command -v python3 >/dev/null 2>&1; then
    if python3 -m json.tool .mcp.json >/dev/null 2>&1; then
      ok ".mcp.json valid JSON"
      COUNT=$(json_query "len(data.get('mcpServers', {}))")
      ARGS=$(json_query "'\n'.join(str(arg) for server in data.get('mcpServers', {}).values() for arg in server.get('args', []))")
      FS_ARGS=$(json_query "'\n'.join(str(arg) for arg in data.get('mcpServers', {}).get('filesystem', {}).get('args', []))")
    else
      ng ".mcp.json khong valid JSON"
      COUNT=0
      ARGS=""
      FS_ARGS=""
    fi
  else
    ng "Khong co jq/python3 de validate .mcp.json"
    COUNT=0
    ARGS=""
    FS_ARGS=""
  fi

  if [ "$COUNT" -ge 4 ]; then
    ok ".mcp.json co $COUNT MCP server (>=4)"
  else
    ng ".mcp.json chi co $COUNT server (can >=4)"
  fi

  if echo "$ARGS" | grep -qE '@latest|@main'; then
    ng "Co server dung @latest hoac @main (khong pin version)"
  else
    ok "Tat ca MCP server version pinned"
  fi
else
  ng ".mcp.json khong ton tai"
  FS_ARGS=""
fi

# MH3: Claude MCP can list connected servers if Claude Code is installed
echo "[2] Claude MCP connection..."
if command -v claude >/dev/null 2>&1; then
  if claude mcp list 2>&1 | grep -qE "✓|Connected"; then
    ok "claude mcp list shows Connected servers"
  else
    ng "claude mcp list khong co server Connected"
  fi
else
  skip "Claude Code CLI chua cai - bo qua check ket noi thuc"
fi

# MH4: debug-session log exists
echo "[3] Debug session log..."
if [ -f debug-session-day2.md ] || [ -f docs/debug-session-day2.md ]; then
  ok "debug-session-day2.md ton tai"
else
  ng "debug-session-day2.md khong ton tai (can 1 case study)"
fi

# MH5: Filesystem MCP allow-list is scoped
echo "[4] Filesystem allow-list..."
if [ -f .mcp.json ]; then
  if echo "$FS_ARGS" | grep -qE '^/$|^\$HOME$|/home/[^/]+$'; then
    ng "Filesystem MCP allow-list qua rong (root, HOME, hoac home dir)"
  else
    ok "Filesystem MCP allow-list hop ly"
  fi
fi

echo
echo "=== Ket qua: $PASS PASS / $FAIL FAIL ==="
[ "$FAIL" -eq 0 ] && green "Day 2 OK" || { red "Co FAIL - xem Day2 spec/lab guide"; exit 1; }
