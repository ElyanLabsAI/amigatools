#!/bin/bash
# run_test.sh - Mastodon-on-the-Amiga in-guest integration test.
#
# Starts a host mock proxy (no API key/token needed), boots AROS m68k
# headless in FS-UAE, lets S/startup-sequence run the mastodon client
# through the proxy, and verifies from the host that:
#   1. `mastodon timeline` rendered the 3 mock toots (incl. the boost) into
#      SYS:masto.log, and
#   2. `mastodon post` got back a created status id/url from the mock.
#
# PARALLELISM: several other agents run FS-UAE at the same time in this
# repo. This script is scoped to Xvfb display :82 and proxy port 8812 ONLY,
# and only ever kills the specific pids it itself started - never a broad
# `pkill fs-uae` / `pkill Xvfb`.
#
# Usage: ./run_test.sh
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
SHARED="$HERE/shared"
CFG="$HERE/mastodon.fs-uae"
SCREENSHOT_DIR="$HERE/screenshots"
DISPLAY_NUM=":82"
PORT=8812
LOG="$SHARED/masto.log"
DONE="$SHARED/masto_done.txt"

mkdir -p "$SCREENSHOT_DIR"

echo "== Mastodon on the Amiga: in-guest test =="

# 1. clean prior output (and FS-UAE .uaem sidecars) so results are fresh
rm -f "$LOG" "$LOG.uaem" "$DONE" "$DONE.uaem"

XVFB_PID=""
PROXY_PID=""
FSUAE_PID=""

cleanup() {
    # Only kill the pids WE started - never a broad pkill (5 other agents
    # run fs-uae/Xvfb concurrently on this host).
    if [ -n "$FSUAE_PID" ]; then kill "$FSUAE_PID" 2>/dev/null; fi
    if [ -n "$PROXY_PID" ]; then kill "$PROXY_PID" 2>/dev/null; fi
    if [ -n "$XVFB_PID" ]; then kill "$XVFB_PID" 2>/dev/null; fi
    wait 2>/dev/null
}
trap cleanup EXIT

# 2. start our own Xvfb on :82 (not xvfb-run, so we can screenshot the same
#    display fs-uae is drawing to)
if [ -e "/tmp/.X82-lock" ]; then
    echo "FAIL: /tmp/.X82-lock already exists - display :82 is in use"
    exit 1
fi
Xvfb "$DISPLAY_NUM" -screen 0 1024x768x24 >/tmp/mastodon_xvfb.log 2>&1 &
XVFB_PID=$!
sleep 1
if ! DISPLAY="$DISPLAY_NUM" xdpyinfo >/dev/null 2>&1; then
    echo "FAIL: Xvfb $DISPLAY_NUM did not come up"; cat /tmp/mastodon_xvfb.log; exit 1
fi
echo "Xvfb $DISPLAY_NUM up (pid $XVFB_PID)"

# 3. start the mock proxy, bound to 0.0.0.0 so guest bsdsocket (127.0.0.1)
#    reaches it
python3 "$HERE/../proxy/mastodon_amiga_proxy.py" --mock --bind 0.0.0.0 --port "$PORT" \
    >/tmp/mastodon_mock.log 2>&1 &
PROXY_PID=$!
sleep 1
if ! curl -s "http://127.0.0.1:$PORT/health" >/dev/null; then
    echo "FAIL: mock proxy did not start on port $PORT"; cat /tmp/mastodon_mock.log; exit 1
fi
echo "mock proxy up on 0.0.0.0:$PORT (pid $PROXY_PID)"

# 4. boot headless on our own Xvfb :82 (timeout guards against a hung emulator)
echo "booting AROS headless on DISPLAY=$DISPLAY_NUM (up to 180s) ..."
DISPLAY="$DISPLAY_NUM" fs-uae "$CFG" >/tmp/mastodon_fsuae.log 2>&1 &
FSUAE_PID=$!
echo "fs-uae up (pid $FSUAE_PID)"

# 5. poll for the guest's completion marker (or the emulator dying early)
for i in $(seq 1 180); do
    if [ -f "$DONE" ]; then
        echo "guest finished after ${i}s"
        break
    fi
    kill -0 "$FSUAE_PID" 2>/dev/null || { echo "fs-uae exited early after ${i}s"; break; }
    sleep 1
done

# 6. screenshot the display before tearing anything down
DISPLAY="$DISPLAY_NUM" import -window root "$SCREENSHOT_DIR/mastodon.png" 2>/tmp/mastodon_import.log
if [ -s "$SCREENSHOT_DIR/mastodon.png" ]; then
    echo "screenshot saved: $SCREENSHOT_DIR/mastodon.png"
else
    echo "WARN: screenshot capture may have failed"; cat /tmp/mastodon_import.log
fi

# 7. stop only what we started
sleep 1
kill "$FSUAE_PID" 2>/dev/null
kill "$PROXY_PID" 2>/dev/null
kill "$XVFB_PID" 2>/dev/null
sleep 1
FSUAE_PID=""; PROXY_PID=""; XVFB_PID=""   # already handled, skip in trap

# 8. verdict
echo
echo "== evidence =="
PASS=1

if [ -f "$LOG" ]; then
    echo "--- SYS:masto.log ---"
    cat "$LOG"
    echo "----------------------"

    if grep -q "boot OK" "$LOG"; then
        echo "PASS: guest booted and startup-sequence ran"
    else
        echo "FAIL: boot marker not found"; PASS=0
    fi

    if grep -q "@alice" "$LOG" && grep -q "Hello from the mock Fediverse" "$LOG"; then
        echo "PASS: timeline rendered alice's mock toot"
    else
        echo "FAIL: alice's mock toot not found in timeline output"; PASS=0
    fi

    if grep -q "carol@retro.example" "$LOG" && grep -q "\[boost\]" "$LOG" && grep -q "Boosted toot: retro computing rules" "$LOG"; then
        echo "PASS: timeline read through carol's boost correctly"
    else
        echo "FAIL: boost read-through not found in timeline output"; PASS=0
    fi

    if grep -q "dave" "$LOG" && grep -q "No AmiSSL needed" "$LOG"; then
        echo "PASS: timeline rendered dave's mock toot"
    else
        echo "FAIL: dave's mock toot not found in timeline output"; PASS=0
    fi

    if grep -q "Tooting from an Amiga" "$LOG" && grep -q "mock.example/@amiga/2001" "$LOG" && grep -q "status id 2001" "$LOG"; then
        echo "PASS: post succeeded, mock returned id/url"
    else
        echo "FAIL: post response (id/url) not found in log"; PASS=0
    fi
else
    echo "FAIL: masto.log was never created (guest did not boot/run)"; PASS=0
fi

echo
echo "--- mock proxy log ---"; cat /tmp/mastodon_mock.log
echo

if [ "$PASS" = "1" ]; then
    echo "RESULT: PASS"
    exit 0
else
    echo "RESULT: FAIL"
    exit 1
fi
