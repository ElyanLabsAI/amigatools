#!/bin/bash
# SPDX-License-Identifier: MIT
# run_test.sh - Amiga MCP server in-guest integration test.
#
# Boots AROS m68k headless in FS-UAE, lets S/startup-sequence run the MCP
# server (mcp-amiga) driven by AmigaDOS stdio redirection (requests.txt in,
# responses.txt out), then verifies from the host that:
#   1. responses.txt contains valid JSON-RPC responses (initialize, tools/list
#      with 3 tools, tools/call content blocks), and
#   2. the write_file tool actually created SYS:mcp_touched.txt in shared/.
#
# PARALLELISM: five other agents may run FS-UAE at the same time. This script
# uses ONLY Xvfb display :84 and kills ONLY the fs-uae pid it launched and its
# own Xvfb :84. It never broadly pkills fs-uae or Xvfb.
#
# Usage: ./run_test.sh
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
SHARED="$HERE/shared"
CFG="$HERE/mcp.fs-uae"
SHOT="$HERE/screenshots/mcp.png"
DISPLAY_NUM=":84"

RESP="$SHARED/responses.txt"
TOUCHED="$SHARED/mcp_touched.txt"
DONE="$SHARED/mcp_done.txt"
BOOT="$SHARED/mcp_boot.txt"

echo "== Amiga MCP server in-guest test =="

# 1. clean prior output (and FS-UAE .uaem sidecars) so results are fresh
rm -f "$RESP" "$RESP.uaem" "$TOUCHED" "$TOUCHED.uaem" \
      "$DONE" "$DONE.uaem" "$BOOT" "$BOOT.uaem"

# 2. start our own Xvfb on :84 (do NOT touch other displays)
Xvfb "$DISPLAY_NUM" -screen 0 1024x768x24 >/tmp/mcp_xvfb84.log 2>&1 &
XVFB_PID=$!
sleep 2
if ! kill -0 "$XVFB_PID" 2>/dev/null; then
    echo "FAIL: Xvfb :84 did not start"; cat /tmp/mcp_xvfb84.log; exit 1
fi
echo "Xvfb $DISPLAY_NUM up (pid $XVFB_PID)"

# 3. boot fs-uae headless in the background, bound to our display only
DISPLAY="$DISPLAY_NUM" fs-uae "$CFG" >/tmp/mcp_fsuae.log 2>&1 &
FSUAE_PID=$!
echo "fs-uae booting (pid $FSUAE_PID) ..."

# 4. poll for the guest completion marker (up to ~150s)
DONE_OK=0
for i in $(seq 1 150); do
    if [ -f "$DONE" ]; then DONE_OK=1; break; fi
    if ! kill -0 "$FSUAE_PID" 2>/dev/null; then
        echo "note: fs-uae pid exited early at ${i}s"; break
    fi
    sleep 1
done
echo "waited ${i}s (done marker: $DONE_OK)"

# 5. give the guest a moment to flush files
sleep 2

# 6. screenshot the console (our display only)
DISPLAY="$DISPLAY_NUM" import -window root "$SHOT" 2>/tmp/mcp_import.log \
    && echo "screenshot -> $SHOT" || { echo "screenshot failed"; cat /tmp/mcp_import.log; }

# 7. stop ONLY our own fs-uae pid and our own Xvfb :84
kill -9 "$FSUAE_PID" 2>/dev/null
sleep 1
kill -9 "$XVFB_PID" 2>/dev/null

# 8. verdict
echo
echo "== evidence =="
PASS=1

if [ -f "$BOOT" ]; then
    echo "PASS: guest booted (mcp_boot.txt present)"
else
    echo "FAIL: guest never wrote mcp_boot.txt (did not boot/run startup)"; PASS=0
fi

if [ -f "$RESP" ]; then
    echo "--- SYS:responses.txt ---"
    cat "$RESP"
    echo "-------------------------"
    grep -q '"serverInfo":{"name":"amiga-mcp"' "$RESP" \
        && echo "PASS: initialize result present" || { echo "FAIL: no initialize result"; PASS=0; }
    grep -q '"read_file"' "$RESP" && grep -q '"write_file"' "$RESP" && grep -q '"run_command"' "$RESP" \
        && echo "PASS: tools/list has all 3 tools" || { echo "FAIL: tools/list missing tools"; PASS=0; }
    grep -q '"content":\[{"type":"text"' "$RESP" \
        && echo "PASS: tools/call returned content blocks" || { echo "FAIL: no tools/call content"; PASS=0; }
else
    echo "FAIL: responses.txt was never created"; PASS=0
fi

if [ -f "$TOUCHED" ]; then
    echo "PASS: write_file tool created mcp_touched.txt :"
    echo "  \"$(cat "$TOUCHED")\""
else
    echo "FAIL: write_file did not create mcp_touched.txt"; PASS=0
fi

echo
if [ "$PASS" = "1" ]; then
    echo "RESULT: PASS"; exit 0
else
    echo "RESULT: FAIL"; exit 1
fi
