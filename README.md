# AmigaTools by Elyan Labs

[![BCOS Certified](https://img.shields.io/badge/BCOS-Certified-brightgreen?style=flat)](https://rustchain.org/bcos/) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Modern software for the classic Commodore Amiga. Native Motorola 68k
(m68k) apps for AmigaOS 3.x and AROS: a web (Gemini) browser, Mastodon and
Nostr clients, an MCP server, a Claude AI client, the Lua language, the
Amiga's own speech voice, and of course the Boing Ball. No emul-only
tricks and no Node.js. Real C, cross-compiled to real AmigaOS executables,
tested inside FS-UAE and on real Workbench 3.1.

If you have an Amiga 500, 1200, 4000, a Vampire, a MiSTer core, or just
FS-UAE, these run on it.

## The tools

| Tool | What it does |
|------|--------------|
| `gemini/` | A Gemini protocol (`gemini://`) browser. TLS via AmiSSL, a `text/gemini` renderer with a numbered link index, redirects, and an interactive browse loop. The web the Amiga can actually run. |
| `mastodon/` | A Mastodon / Fediverse client. Read your timeline and post a toot over HTTPS. Your token stays on the Amiga. NOTE: the host logic is verified but the m68k build currently crashes in-guest in the network path (a known bug, see its README). |
| `nostr/` | A Nostr client. Reads notes from a relay over a TLS WebSocket (RFC6455 handshake and framing, NIP-01). Publishing is a marked TODO (secp256k1 Schnorr). |
| `mcp/` | A Model Context Protocol server that runs ON the Amiga, exposing read_file / write_file / run_command as MCP tools over stdio JSON-RPC. A modern AI agent can drive the Amiga. |
| `claude/` | A native Anthropic Claude client with a real tool-use loop. Chats, and reads/writes files and runs AmigaDOS commands at Claude's instruction, behind a confirm gate. |
| `lua/` | Lua 5.4.7 ported to m68k (`lua`, `luac`), configured for the toolchain. |
| `narrator/` | A `say` command that speaks text through the Amiga's built-in narrator.device, the iconic robotic voice, from C. |
| `boing/` | The Boing Ball as native m68k code. Because obviously. |
| `common/` | Shared code every tool reuses: the AmiSSL and bsdsocket transport, dependency-free JSON helpers, and the dev guide. |

Each tool has its own README with build and usage, a Makefile that
cross-compiles with one Docker image, host-tests for its pure logic, and a
committed AmigaOS binary you can grab without a toolchain.

## In-emulator test status (honest)

Every tool is cross-compiled to a verified AmigaOS hunk and host-tested. Beyond
that, here is exactly what has been run inside a booted Amiga (FS-UAE), with the
evidence in each tool's `test/`:

| Tool | In-guest status |
|------|-----------------|
| claude | Verified. Haiku scaffolded, compiled (vbcc), and ran a C program on real Workbench 3.1. |
| gemini | Verified. Fetched a capsule through the proxy and rendered gemtext on AROS. |
| nostr | Verified (read path). WebSocket handshake and note display against a relay on AROS. |
| mcp | Verified. `write_file` and `read_file` acted on the Amiga; `run_command` works with a mounted `T:`. |
| lua | Runs on real Workbench 3.1 (prints correct output). Fails on the bare AROS ROM, which lacks the mathieee libraries. |
| boing | Renders on AROS. |
| narrator | Loads and runs, but fails gracefully because neither AROS nor Commodore Workbench ships `translator.library`. Needs a ROM/setup that has it. |
| mastodon | Does NOT run in-guest yet. The m68k build crashes in the network path (host logic verified). A known bug. |

## Build

One image cross-compiles everything: `amigadev/crosstools:m68k-amigaos`.

```
cd gemini && make          # cross-compile to bin/gemini
cd gemini && make host-test # run the host self-tests
```

See `docs/AMIGA_APP_DEV_GUIDE.md` to add your own tool. It has the m68k
traps that will otherwise cost you hours (use `-m68020`, no libnix
`__stack` global, `fflush` stdout, open `bsdsocket` v3, AmigaDOS is not
bash) and the reusable transport and JSON code.

## Honest scope

- Not the first at everything. AmigaGPT already does Claude chat on the
  Amiga; what is new here is the agentic tool-use loop on 68k. We state
  prior art per tool in each README and do not claim false firsts.
- The TLS tools ship two transports: AmiSSL direct HTTPS from the Amiga,
  and a small host proxy for machines with no TLS library (which also
  keeps API keys off the Amiga). In-emulator tests use the proxy path.

## Related

- [RustChain Amiga Edition](https://github.com/Scottcjn/rustchain-amiga) —
  the Proof-of-Antiquity blockchain miner and SDK for 68k AmigaOS, where
  these tools started before moving here.
- [Elyan Labs](https://elyanlabs.ai) — the lab.
- [RustChain](https://rustchain.org) — the chain, and the BCOS certification.

## License

MIT (see `LICENSE`). Certified under Elyan Labs' Beacon Certified Open
Source program (see `BCOS.md`).
