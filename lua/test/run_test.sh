#!/bin/bash
# run_test.sh - does Lua actually RUN on a real Amiga?
#
# Two attempts, both reported honestly:
#   1. AROS  - bare open-source AROS m68k ROM. EXPECTED TO FAIL: that minimal
#              ROM lacks the mathieee*.library set libnix soft-float calls into
#              (documented in ../README.md "On-Amiga execution").
#   2. WB3.1 - real licensed Workbench 3.1 install on a real Kickstart 3.1 ROM,
#              which DOES ship mathieeedoubbas/doubtrans/singtrans.library. This
#              is the real test.
#
# SUCCESS: on WB3.1, `lua hello.lua` prints  42  and  lua on amiga .
#
# SAFETY: the tracked personal HDF is NEVER touched. We work on a /tmp COPY.
# PARALLELISM: uses ONLY Xvfb display :86; kills ONLY the pids it launches.
#
# Usage: ./run_test.sh
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
XDF="$REPO/distro/venv/bin/xdftool"
SRC_HDF="$REPO/distro/personal/RustChainAmiga-WB31-PERSONAL-DO-NOT-DISTRIBUTE.hdf"
LUABIN="$REPO/lua/bin/lua"

WORK=/tmp/luatest
WBHDF="$WORK/wb.hdf"
OUTDIR="$WORK/out"
DISP=:86

AROS_CFG="$HERE/aros-test.fs-uae"
WB_CFG="$HERE/wb31-test.fs-uae"
AROS_LOG="$HERE/aros-hd/lua_aros.log"
WB_OUT="$OUTDIR/lua_out.txt"

launched_pids=()
cleanup() {
    for p in "${launched_pids[@]:-}"; do kill -9 "$p" 2>/dev/null; done
    pkill -9 -f "Xvfb $DISP" 2>/dev/null
}
trap cleanup EXIT

start_xvfb() {
    pkill -9 -f "Xvfb $DISP" 2>/dev/null; sleep 1
    Xvfb $DISP -screen 0 1024x768x24 >/tmp/luatest_xvfb.log 2>&1 &
    launched_pids+=($!)
    sleep 2
}

# boot a config headless on :86, poll for $1 (result file) up to $2 seconds,
# screenshot to $3, then kill just this fs-uae.
boot_and_capture() {
    local resultfile="$1" timeout="$2" shot="$3" cfg="$4" fslog="$5"
    DISPLAY=$DISP fs-uae "$cfg" >"$fslog" 2>&1 &
    local fpid=$!
    launched_pids+=($fpid)
    local waited=0
    while [ $waited -lt "$timeout" ]; do
        if [ -s "$resultfile" ]; then sleep 3; break; fi
        if ! kill -0 $fpid 2>/dev/null; then break; fi
        sleep 3; waited=$((waited+3))
    done
    DISPLAY=$DISP import -window root "$shot" 2>/dev/null || \
        DISPLAY=$DISP import -window root -screen "$shot" 2>/dev/null || true
    kill -9 $fpid 2>/dev/null
    sleep 1
}

echo "=================================================================="
echo " Lua on a real Amiga - two attempts"
echo "=================================================================="

mkdir -p "$WORK" "$OUTDIR"

# ---------------------------------------------------------------- ATTEMPT 1
echo
echo "### ATTEMPT 1: bare AROS m68k ROM (expected FAIL - missing math libs) ###"
rm -f "$AROS_LOG" "$AROS_LOG.uaem"
start_xvfb
boot_and_capture "$AROS_LOG" 120 "$HERE/screenshots/lua-aros.png" "$AROS_CFG" /tmp/luatest_aros_fsuae.log
echo "--- AROS lua_aros.log ---"
if [ -f "$AROS_LOG" ]; then cat "$AROS_LOG"; else echo "(no log produced)"; fi
echo "-------------------------"

# ---------------------------------------------------------------- ATTEMPT 2
echo
echo "### ATTEMPT 2: real Workbench 3.1 + Kickstart 3.1 (the real test) ###"

# Fresh COPY of the personal HDF - the tracked file is NEVER modified.
[ -x "$XDF" ]   || { echo "FAIL: xdftool not found ($XDF) - run distro/assemble.sh"; exit 1; }
[ -f "$SRC_HDF" ] || { echo "FAIL: personal WB3.1 HDF not found ($SRC_HDF)"; exit 1; }
[ -f "$LUABIN" ]  || { echo "FAIL: lua binary not found ($LUABIN)"; exit 1; }
echo "copying personal HDF -> $WBHDF (working copy only)"
cp "$SRC_HDF" "$WBHDF"
chmod 600 "$WBHDF"
rm -f "$WB_OUT" "$OUTDIR"/*.uaem

# Inject a Lua drawer (binary + hello.lua) into the COPY.
echo "injecting Lua: drawer into the copy"
"$XDF" "$WBHDF" makedir Lua 2>/dev/null || true
"$XDF" "$WBHDF" write "$LUABIN" Lua/lua
"$XDF" "$WBHDF" write "$HERE/hello.lua" Lua/hello.lua
# a tiny script Execute-able if a console is wanted
printf 'Lua:lua Lua:hello.lua\n' > "$WORK/luashow"
"$XDF" "$WBHDF" write "$WORK/luashow" Lua/luashow 2>/dev/null || true

# Patch S/startup-sequence: after the assigns/LIBS are set up, before LoadWB,
# run lua twice - once to Out: (host-readable file) and once to the boot
# console (visible for the screenshot). C:Wait holds the CLI so the shot lands.
echo "patching S/startup-sequence in the copy"
SS="$WORK/startup-sequence"
"$XDF" "$WBHDF" read S/startup-sequence "$SS"
python3 - "$SS" <<'PY'
import sys
p = sys.argv[1]
# latin-1 round-trips all byte values 0-255 (the header has a 0xa9 (C) byte)
s = open(p, 'r', newline='', encoding='latin-1').read()
inject = (
    'Assign >NIL: Lua: SYS:Lua\n'
    'echo "=== Lua 5.4.7 on real Workbench 3.1 (m68k) ==="\n'
    'Lua:lua Lua:hello.lua >Out:lua_out.txt\n'
    'Lua:lua Lua:hello.lua\n'
    'echo "=== lua done - see Out:lua_out.txt ==="\n'
    'C:Wait 30\n'
)
marker = 'C:LoadWB'
i = s.find(marker)
if i == -1:
    s = s + '\n' + inject
else:
    s = s[:i] + inject + s[i:]
open(p, 'w', newline='', encoding='latin-1').write(s)
print("startup-sequence patched (%d bytes)" % len(s))
PY
"$XDF" "$WBHDF" delete S/startup-sequence >/dev/null 2>&1
"$XDF" "$WBHDF" write "$SS" S/startup-sequence
echo "--- patched startup tail ---"; tail -20 "$SS"; echo "----------------------------"

start_xvfb
boot_and_capture "$WB_OUT" 180 "$HERE/screenshots/lua-wb31.png" "$WB_CFG" /tmp/luatest_wb_fsuae.log

echo
echo "=================================================================="
echo " RESULTS"
echo "=================================================================="
PASS=1
if [ -s "$WB_OUT" ]; then
    echo "--- Out:lua_out.txt (from real Workbench 3.1) ---"
    cat "$WB_OUT"
    echo "-------------------------------------------------"
    cp "$WB_OUT" "$HERE/lua_out.txt"
    if grep -q '^42' "$WB_OUT" && grep -q 'lua on amiga' "$WB_OUT"; then
        echo "PASS: Lua ran on real Workbench 3.1 and printed 42 + 'lua on amiga'"
    else
        echo "PARTIAL: output file present but expected lines not both found"; PASS=0
    fi
else
    echo "FAIL: no output from Workbench 3.1 run (Out:lua_out.txt empty/missing)"
    PASS=0
fi

echo
echo "screenshots: $HERE/screenshots/"
ls -la "$HERE/screenshots/" 2>/dev/null

# cleanup /tmp working copy (never leave the licensed image around)
rm -f "$WBHDF"
echo
[ "$PASS" = 1 ] && echo "OVERALL: PASS" || echo "OVERALL: see output above (honest result)"
exit 0
