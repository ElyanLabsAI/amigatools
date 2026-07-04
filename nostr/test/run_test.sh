#!/bin/bash
# run_test.sh - Nostr client on the Amiga in-guest READ-PATH test.
#
# Starts a host mock Nostr relay (nostr/tools/mock_relay.py's logic, bound to
# 0.0.0.0 so the guest can reach it), boots AROS m68k headless in FS-UAE, lets
# S/startup-sequence run bin/nostr-proxy (plain ws://, no AmiSSL needed)
# against it, and verifies from the host that the client completed the
# WebSocket handshake and printed the two canned notes into SYS:nostr.log.
#
# PUBLISH is a known TODO in the client (needs secp256k1/BIP340 signing) and
# is NOT exercised here. This tests the READ path only.
#
# Parallelism: this repo runs several FS-UAE instances concurrently. This
# script uses ONLY Xvfb display :83 and host port 8813, and only ever kills
# the specific fs-uae/Xvfb pids it launched itself (never a broad pkill).
#
# Usage: ./run_test.sh
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
SHARED="$HERE/shared"
CFG="$HERE/nostr.fs-uae"
RELAY="$HERE/mock_relay_host.py"
PORT=8813
DISP=":83"
LOG="$SHARED/nostr.log"
DONE="$SHARED/nostr_done.txt"
BOOT_TIMEOUT=180

echo "== Nostr Amiga in-guest read-path test =="

# 0. clean prior output (and FS-UAE .uaem sidecars) so results are fresh.
#    Do NOT touch other agents' emulators/Xserver - only our own pids below.
rm -f "$LOG" "$LOG.uaem" "$DONE" "$DONE.uaem"
mkdir -p "$HERE/screenshots"

# 1. start the mock relay on the host, bound to 0.0.0.0:8813 so the guest's
#    bsdsocket passthrough (guest 127.0.0.1 -> host loopback) reaches it.
python3 "$RELAY" "$PORT" >/tmp/nostr_mock_relay_8813.log 2>&1 &
RELAY_PID=$!
sleep 1
if ! kill -0 "$RELAY_PID" 2>/dev/null; then
    echo "FAIL: mock relay did not start"; cat /tmp/nostr_mock_relay_8813.log; exit 1
fi
echo "mock relay up on 0.0.0.0:$PORT (pid $RELAY_PID)"

# 2. our own private Xvfb on display :83 (not xvfb-run, so we control the pid
#    precisely and never touch another agent's Xvfb/display).
Xvfb "$DISP" -screen 0 1024x768x24 >/tmp/nostr_xvfb_83.log 2>&1 &
XVFB_PID=$!
sleep 1
if ! kill -0 "$XVFB_PID" 2>/dev/null; then
    echo "FAIL: Xvfb $DISP did not start"; cat /tmp/nostr_xvfb_83.log
    kill "$RELAY_PID" 2>/dev/null
    exit 1
fi
echo "Xvfb $DISP up (pid $XVFB_PID)"

cleanup() {
    # Only ever kill the exact pids we launched in this script.
    kill "$FSUAE_PID" 2>/dev/null
    kill "$RELAY_PID" 2>/dev/null
    kill "$XVFB_PID" 2>/dev/null
    wait 2>/dev/null
}
trap cleanup EXIT

# 3. boot headless on our private display (timeout guards a hung emulator).
echo "booting AROS headless on DISPLAY=$DISP (up to ${BOOT_TIMEOUT}s) ..."
DISPLAY="$DISP" timeout "$BOOT_TIMEOUT" fs-uae "$CFG" >/tmp/nostr_fsuae.log 2>&1 &
FSUAE_PID=$!

# 4. poll for the guest's completion marker (or the emulator dying early)
echo "waiting for the guest (up to ${BOOT_TIMEOUT}s)..."
for i in $(seq "$BOOT_TIMEOUT"); do
    if [ -f "$DONE" ] && grep -q "nostr test done" "$DONE" 2>/dev/null; then
        echo "guest finished after ${i}s"
        break
    fi
    kill -0 "$FSUAE_PID" 2>/dev/null || { echo "fs-uae exited early after ${i}s"; break; }
    sleep 1
done

# 5. take a screenshot before tearing down (F12+S is FS-UAE's screenshot key;
#    easier to just ask FS-UAE to dump one via its config'd output dir - we
#    trigger it by sending F11 is not reliable headless, so we rely on the
#    screenshots_output_dir + an explicit screenshot request via fs-uae-launcher
#    is unavailable; fall back to importing the framebuffer with `import` if
#    available, else xwd, against our own DISPLAY only).
sleep 2
SCREEN="$HERE/screenshots/nostr.png"
if command -v import >/dev/null 2>&1; then
    DISPLAY="$DISP" import -window root "$SCREEN" 2>/tmp/nostr_screenshot.log
elif command -v xwd >/dev/null 2>&1 && command -v convert >/dev/null 2>&1; then
    DISPLAY="$DISP" xwd -root -silent 2>/tmp/nostr_screenshot.log | convert xwd:- "$SCREEN"
else
    echo "(no screenshot tool available: need ImageMagick 'import' or xwd+convert)"
fi
[ -f "$SCREEN" ] && echo "screenshot saved: $SCREEN"

# 6. stop everything we started (never a broad pkill; see cleanup() above)
kill "$FSUAE_PID" 2>/dev/null
sleep 1

# 7. verdict
echo
echo "== evidence =="
PASS=1

if [ -f "$LOG" ]; then
    echo "--- SYS:nostr.log ---"
    cat "$LOG"
    echo "---------------------"
    if grep -q "WebSocket open" "$LOG"; then
        echo "PASS: WebSocket handshake completed in-guest"
    else
        echo "FAIL: no WebSocket handshake confirmation in nostr.log"; PASS=0
    fi
    if grep -q "Hello from a real WebSocket relay to the Amiga" "$LOG" && \
       grep -q "Second note" "$LOG"; then
        echo "PASS: both canned note contents were printed in-guest"
    else
        echo "FAIL: note content not found in nostr.log"; PASS=0
    fi
    if grep -q "end of stored events" "$LOG"; then
        echo "PASS: EOSE handling confirmed"
    else
        echo "FAIL: EOSE marker not found in nostr.log"; PASS=0
    fi
else
    echo "FAIL: nostr.log was never created (guest did not boot/run)"; PASS=0
fi

echo
echo "--- mock relay log ---"; cat /tmp/nostr_mock_relay_8813.log
echo

if [ "$PASS" = "1" ]; then
    echo "RESULT: PASS (read path)"
    exit 0
else
    echo "RESULT: FAIL"
    exit 1
fi
