# common

Shared building blocks every AmigaTools app reuses. Each app currently vendors
its own copy of these so it stays self-contained and buildable in isolation;
this directory is the canonical reference and the place to fix a shared bug.

- `rtc_common.c` / `.h` — bsdsocket open/close (v3), a recv-until-EOF HTTP
  helper, small parsing helpers, and Ctrl-C/break handling.
- The AmiSSL TLS init/teardown pattern lives in `claude/claude.c`
  (`amissl_init`, `amissl_cleanup`, `amissl_post`); the TLS tools copy it.
- The dependency-free JSON helpers (`json_escape`, `json_unescape`, `find_key`,
  `get_json_string`, `get_raw_span`, `rtc_json_next_obj`) also live in
  `claude/claude.c` and are copied into the tools that parse JSON.

See `../docs/AMIGA_APP_DEV_GUIDE.md` for the build recipe and the m68k gotchas.
