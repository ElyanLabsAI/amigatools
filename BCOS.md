# BCOS - Beacon Certified Open Source (L1, self-assessed)

[![BCOS L1 self-assessed](https://img.shields.io/badge/BCOS-L1%20self--assessed-blue?style=flat)](BCOS.md)

This repository meets the **L1 tier** of the Beacon Certified Open Source
(BCOS) program by [Elyan Labs](https://elyanlabs.ai) on a **self-assessed**
basis. The score is reproducible (see the note on measurement below). It has
**not** been anchored on-chain yet; that step is pending and needs an explicit
go-ahead. License: `MIT`.

## Self-assessment

Run locally with the BCOS v2 engine. Score: **85 / 100**, L1 threshold is 60.

| Check (max) | Score | Notes |
|-------------|-------|-------|
| Static analysis (20) | 20 | semgrep run; all 21 findings fixed or justified inline |
| Vulnerability scan (25) | 25 | no third-party dependency manifests, so nothing declared can be vulnerable |
| Test evidence (10) | 10 | `tests/run_all_tests.sh` runs every app's host self-test; CI builds all 8 apps |
| SBOM completeness (10) | 7 | real CycloneDX SBOM at `sbom.json` listing the actual components |
| License compliance (20) | 13 | SPDX MIT on all our own code; capped by the vendored third-party AmiSSL SDK |
| Dependency freshness (5) | 5 | no dependency manifests, so nothing can be out of date |
| Review attestation (10) | 5 | L1 tier (agent plus human review) |

- Cert id (local): `BCOS-816f0264`
- Commitment (local, not anchored): `816f02647f373c8b7366ad85897f3e7f06d88db7417444fbfb61206cdb1390e7`

### On reproducibility

An earlier run of the engine scored this repo anywhere from 57 to 85 depending
on the machine, because two checks (vulnerability scan and dependency freshness)
audited the Python environment of whichever host ran the scanner rather than
this project. amigatools is C for m68k with a few standard-library-only Python
helper scripts, so it has zero third-party runtime dependencies of its own. The
BCOS engine has since been fixed to scan the project's own declared
dependencies rather than the scanner's ambient environment, so the score is now
the same regardless of where it runs. The 85 above is measured from an ordinary
developer machine, not a specially cleaned one.

### Why license compliance is capped at 13/20

The vendored AmiSSL SDK under `common/amissl-sdk/` is 172 upstream OpenSSL/AmiSSL
headers (Apache-2.0), left intentionally untagged: we did not author them and
tagging them MIT would misstate their license. That holds SPDX coverage at ~37%
of all code files even though every one of our own files is tagged. Raising it
would require the SDK gaining upstream SPDX headers or being removed from the
scanned tree, neither of which this repo controls.

## What BCOS certifies

| Check | Description |
|-------|-------------|
| License Compliance | SPDX headers plus OSI-compatible dependencies |
| Vulnerability Scan | CVE (OSV) scan of the project's declared dependencies |
| Static Analysis | Semgrep rule set |
| SBOM | Software Bill of Materials |
| Dependency Freshness | Percentage of declared deps at latest version |
| Test Evidence | Test infrastructure and in-emulator evidence |
| Review Attestation | Human or agent review tier |

## Verify it yourself

```bash
pip install semgrep pip-audit cyclonedx-bom pip-licenses
python3 bcos_engine.py /path/to/amigatools --tier L1 --json
```

## Honesty note

An earlier version of this file claimed the repository "is certified" and that a
commitment was "anchored to the RustChain ledger" before any grade had been
earned and with nothing written on-chain. That was corrected. The current state
is an honest, reproducible L1 self-assessment. The on-chain anchor and any
directory listing come only after an explicit decision to perform the on-chain
write.

- Organization: [Elyan Labs](https://elyanlabs.ai)
- Chain: [RustChain](https://rustchain.org) (Proof of Antiquity)
- Engine: BCOS v2, free and open source (MIT)
