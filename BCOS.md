# BCOS - Beacon Certified Open Source (in progress)

This repository is **working toward** certification under the Beacon Certified
Open Source (BCOS) program by [Elyan Labs](https://elyanlabs.ai). It is **not
certified yet**. License: `MIT`.

## Current self-assessment

Run locally with the BCOS v2 engine (no on-chain anchoring performed):

| Field | Value |
|-------|-------|
| Trust score | 18 / 100 |
| Tier claimed | L1 (needs >= 60) |
| Tier met | No, not yet |
| Cert id (local) | BCOS-210fc8b1 |
| Commitment (local, not anchored) | `210fc8b1d4807eee7ec2de02e26789e34505be4d4286195de559a911e4245fb4` |

The score is held down by two things we are actively addressing: the vendored
AmiSSL SDK under `common/` (third-party OpenSSL headers with no SPDX tags, which
drag license coverage down) and the static-analysis / vulnerability / SBOM
checks, which need their scanner tooling wired into a repeatable run.

## What BCOS certifies

| Check | Description |
|-------|-------------|
| License Compliance | SPDX headers plus OSI-compatible dependencies |
| Vulnerability Scan | CVE (OSV) scan for known vulnerabilities |
| Static Analysis | Semgrep rule set |
| SBOM | Software Bill of Materials |
| Dependency Freshness | Percentage of deps at latest version |
| Test Evidence | Test infrastructure and in-emulator evidence |
| Review Attestation | Human or agent review tier |

## Verify the self-assessment yourself

```bash
python3 bcos_engine.py . --tier L1 --json
```

## Honesty note

An earlier version of this file claimed the repository "is certified" and that a
commitment was "anchored to the RustChain ledger." Neither was true: no passing
grade had been earned and nothing was written on-chain. That claim has been
removed. When the repository genuinely meets an L1 grade, and only then, the
badge and an on-chain commitment will be added back with real evidence.

- Organization: [Elyan Labs](https://elyanlabs.ai)
- Chain: [RustChain](https://rustchain.org) (Proof of Antiquity)
- Engine: BCOS v2, free and open source (MIT)
