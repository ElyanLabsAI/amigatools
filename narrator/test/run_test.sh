#!/bin/bash
# run_test.sh - narrator say in-guest integration test.
#
# Boots AROS m68k headless in FS-UAE on a PRIVATE Xvfb display (:85 - other
# agents run FS-UAE concurrently on other displays, so we never pkill
# broadly), lets S/startup-sequence run `say --dry-run` and plain `say`,
# then judges from the host-readable shared/say.log plus a screenshot.
#
# Honest expectation: the open-source AROS ROM probably ships neither
# translator.library nor narrator.device, so say erroring out gracefully
# ("cannot open translator.library") is a valid, expected outcome. The test
# verdict is about the harness + the tool's behavior, reported truthfully.
#
# Usage: ./run_test.sh
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
SHARED="$HERE/shared"
CFG="$HERE/narrator.fs-uae"
LOG="$SHARED/say.log"
DONE="$SHARED/say_done.txt"
SHOT="$HERE/screenshots/narrator.png"
DISP=":85"

echo "== narrator say in-guest test =="

# 0. refuse to double-run on our display; kill only OUR stale Xvfb :85
if [ -e "/tmp/.X85-lock" ]; then
    OLD=$(pgrep -f "Xvfb ${DISP}" | head -1 || true)
    if [ -n "${OLD:-}" ]; then
        echo "killing stale Xvfb ${DISP} (pid $OLD)"
        kill -9 "$OLD" 2>/dev/null
        sleep 1
    fi
    rm -f "/tmp/.X85-lock"
fi

# 1. clean prior output (and FS-UAE .uaem sidecars) so results are fresh
rm -f "$LOG" "$LOG.uaem" "$DONE" "$DONE.uaem"
mkdir -p "$HERE/screenshots"

# 2. start our private X server
Xvfb "$DISP" -screen 0 1024x768x24 >/tmp/narrator_xvfb.log 2>&1 &
XVFB=$!
sleep 1
if ! kill -0 "$XVFB" 2>/dev/null; then
    echo "FAIL: Xvfb ${DISP} did not start"; cat /tmp/narrator_xvfb.log; exit 1
fi
echo "Xvfb up on ${DISP} (pid $XVFB)"

# 3. boot headless in the background
echo "booting AROS headless ..."
DISPLAY="$DISP" fs-uae "$CFG" >/tmp/narrator_fsuae.log 2>&1 &
EMU=$!

# 4. poll for the guest to finish (startup-sequence writes say_done.txt last)
WAITED=0
while [ $WAITED -lt 120 ]; do
    if [ -f "$DONE" ] && [ -f "$LOG" ]; then
        echo "guest finished after ${WAITED}s"
        break
    fi
    if ! kill -0 "$EMU" 2>/dev/null; then
        echo "fs-uae exited early after ${WAITED}s"
        break
    fi
    sleep 3
    WAITED=$((WAITED + 3))
done
sleep 2   # let the guest flush file buffers to the host dir

# 5. screenshot the emulator window before tearing down
import -display "$DISP" -window root "$SHOT" 2>/dev/null \
    || xwd -display "$DISP" -root 2>/dev/null | convert xwd:- "$SHOT" 2>/dev/null
[ -f "$SHOT" ] && echo "screenshot: $SHOT"

# 6. stop ONLY the processes we launched (never pkill fs-uae broadly)
kill -9 "$EMU" 2>/dev/null
kill -9 "$XVFB" 2>/dev/null
rm -f "/tmp/.X85-lock"
sleep 1

# 7. verdict - judged from the FILE, honestly
echo
echo "== evidence =="
PASS=1

if [ -f "$LOG" ]; then
    echo "--- SYS:say.log ---"
    cat "$LOG"
    echo "-------------------"
    if grep -q "=== done ===" "$LOG"; then
        echo "PASS: startup-sequence ran say to completion"
    else
        echo "WARN: say.log exists but the done marker is missing (guest cut short?)"
        PASS=0
    fi
    if grep -qi "cannot open translator.library" "$LOG"; then
        echo "RESULT DETAIL: translator.library ABSENT in AROS ROM - say errored"
        echo "               gracefully (expected on the open-source ROM)."
    elif grep -qi "cannot open narrator.device" "$LOG"; then
        echo "RESULT DETAIL: translator worked, narrator.device ABSENT - dry-run"
        echo "               phonemes above are real; live speech unavailable."
    elif grep -qE '^/?[A-Z0-9/]+.*\.' "$LOG" | grep -qv "==="; then
        echo "RESULT DETAIL: phoneme output present - full translator path works."
    fi
else
    echo "FAIL: say.log was never created (guest did not boot/run)"; PASS=0
fi

if [ -f "$DONE" ]; then
    echo "PASS: done marker written: \"$(cat "$DONE")\""
else
    echo "FAIL: say_done.txt missing"; PASS=0
fi

echo
if [ "$PASS" = "1" ]; then
    echo "RESULT: PASS (harness ran; see RESULT DETAIL for what say actually did)"
    exit 0
else
    echo "RESULT: FAIL"
    exit 1
fi
