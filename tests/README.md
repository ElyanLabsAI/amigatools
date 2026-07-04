# Tests

This directory is the top-level entry point into amigatools' test
infrastructure. It does not duplicate any test; it runs and indexes the
tests that already live next to each app.

## Two tiers of test, per app

1. **Host-side logic tests** (`make -C <app> host-test` or `<app>/client
   host-test`) -- the same C source that gets cross-compiled for m68k is
   also compiled natively with the host's `cc` and run directly, with no
   AmigaOS, no emulator, no network, and no docker. This covers pure logic:
   parsing, framing, hashing, serialization. Fast (sub-second) and safe to
   run anywhere a C compiler exists.

   | App | Host test target |
   |-----|-------------------|
   | boing | none (no host-testable logic; pure Intuition/graphics demo) |
   | claude | `make -C claude/client host-test` |
   | gemini | `make -C gemini host-test` |
   | lua | `bash lua/build.sh host` (builds host `lua`, runs `lua/host/verify.lua`) |
   | mastodon | `make -C mastodon host-test` |
   | mcp | `make -C mcp host-test` |
   | narrator | none (no host-testable logic; talks to narrator.device) |
   | nostr | `make -C nostr host-test` |

   Run all of the above in one shot with `./tests/run_all_tests.sh`, or
   `make test` from the repo root.

2. **In-guest integration tests** (`<app>/test/run_test.sh`) -- boot a real
   or emulated AmigaOS/AROS m68k target in FS-UAE, run the actual
   cross-compiled binary against a host-side mock server or proxy, and
   verify the guest's output from the host. These need `fs-uae`, the
   `amigadev/crosstools:m68k-amigaos` docker image to build the binary
   first, and (for AROS boots) a kickstart-free AROS ROM already set up in
   the shared FS-UAE config under each `test/` directory.

   `run_all_tests.sh` does **not** launch these automatically: they take
   tens of seconds each, can hang if a prior emulator instance is still
   running, and depend on local FS-UAE/AROS setup that varies by machine
   (see each app's own `test/run_test.sh` and README.md for exact
   prerequisites). Run them individually, e.g.:

   ```
   # boing has no run_test.sh yet -- verified manually via boing/screenshots/
   ./claude/test/run_test.sh
   ./gemini/test/run_test.sh
   ./lua/test/run_test.sh
   ./mastodon/test/run_test.sh
   ./mcp/test/run_test.sh
   ./narrator/test/run_test.sh
   ./nostr/test/run_test.sh
   ```

## CI

`.github/workflows/build.yml` builds every app's m68k binary on every push
and pull request (compile-time verification). It does not run the FS-UAE
in-guest tests, since GitHub's hosted runners are not set up with AROS/Amiga
ROMs; the host-side logic tests in tier 1 above are the CI-friendly subset
and are what `make test` runs.
