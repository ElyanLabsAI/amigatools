#!/bin/bash
# SPDX-License-Identifier: MIT
# run_all_tests.sh - run every app's fast, host-side logic self-test.
#
# This is tier 1 only (see tests/README.md): native `cc` builds of the same
# source that gets cross-compiled for m68k, run directly on the host with no
# AmigaOS, no emulator, no docker, and no network. It is meant to be safe and
# fast enough to run in CI or on any dev machine with a C compiler.
#
# It deliberately does NOT launch the FS-UAE in-guest integration tests
# (each app's test/run_test.sh) -- those take longer, need local FS-UAE/AROS
# setup, and can hang if a previous emulator instance is still around. Run
# those individually; see tests/README.md.
#
# Exit status: 0 if every attempted test passed, 1 if any failed. Apps with
# no host-testable logic are reported as SKIP, not FAIL.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(dirname "$HERE")"
cd "$REPO"

PASS=0
FAIL=0
SKIP=0
FAILED_NAMES=()

run_step() {
    local name="$1"
    shift
    echo "== $name =="
    if "$@"; then
        echo "-- PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "-- FAIL: $name"
        FAIL=$((FAIL + 1))
        FAILED_NAMES+=("$name")
    fi
    echo
}

skip_step() {
    local name="$1" reason="$2"
    echo "== $name =="
    echo "-- SKIP: $name ($reason)"
    echo
    SKIP=$((SKIP + 1))
}

if command -v cc >/dev/null 2>&1; then
    run_step "claude host-test"   make -s -C claude/client host-test
    run_step "gemini host-test"   make -s -C gemini host-test
    run_step "mastodon host-test" make -s -C mastodon host-test
    run_step "mcp host-test"      make -s -C mcp host-test
    run_step "nostr host-test"    make -s -C nostr host-test
else
    skip_step "claude host-test"   "no host cc"
    skip_step "gemini host-test"   "no host cc"
    skip_step "mastodon host-test" "no host cc"
    skip_step "mcp host-test"      "no host cc"
    skip_step "nostr host-test"    "no host cc"
fi

if command -v cc >/dev/null 2>&1 && [ -f lua/src-lua/lua-5.4.7.tar.gz ]; then
    run_step "lua host build+verify" bash lua/build.sh host
else
    skip_step "lua host build+verify" "no host cc or missing lua/src-lua/lua-5.4.7.tar.gz"
fi

skip_step "boing"    "no host-testable logic (Intuition/graphics demo); see boing/screenshots/"
skip_step "narrator" "no host-testable logic (talks to narrator.device); see narrator/test/run_test.sh"

echo "================================================================"
echo "host-test summary: $PASS passed, $FAIL failed, $SKIP skipped"
echo "In-guest FS-UAE integration tests are NOT run by this script."
echo "See tests/README.md for how to run each app's test/run_test.sh."
echo "================================================================"

if [ "$FAIL" -gt 0 ]; then
    echo "failed: ${FAILED_NAMES[*]}"
    exit 1
fi
exit 0
