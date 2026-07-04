# SPDX-License-Identifier: MIT
# Makefile - repo-level convenience targets for amigatools.
#
# Each app builds and tests independently (see <app>/Makefile or
# <app>/client/Makefile); this file just ties them together for a
# one-command sanity check from the repo root.

.PHONY: test clean

# Fast, host-side logic self-tests for every app that has them (native cc,
# no AmigaOS, no emulator, no docker, no network). See tests/README.md for
# what this does and does not cover, and how to run the slower in-guest
# FS-UAE integration tests per app.
test:
	./tests/run_all_tests.sh

clean:
	$(MAKE) -C claude/client clean
	$(MAKE) -C gemini clean
	$(MAKE) -C mastodon clean
	$(MAKE) -C mcp clean
	$(MAKE) -C narrator clean
	$(MAKE) -C nostr clean
