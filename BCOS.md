# BCOS - Beacon Certified Open Source (L1, anchored)

[![BCOS L1 anchored](https://img.shields.io/badge/BCOS-L1%20anchored-brightgreen?style=flat)](https://rustchain.org/bcos/verify/BCOS-5664a2af)

This repository meets the **L1 tier** of the Beacon Certified Open Source
(BCOS) program by [Elyan Labs](https://elyanlabs.ai) and is **anchored on the
RustChain ledger**. License: `MIT`.

- **Cert id**: `BCOS-5664a2af`
- **Commitment** (BLAKE2b-256): `5664a2af80e7796801217262c1457b6333b03d279d682b48a6a283bcd6d9cdc3`
- **Attested commit**: `7f26c6dbdbe5636bc11d4e141f2ac503060e8dd1` (the `v0.1` release)
- **Trust score**: 85 / 100 (L1 threshold is 60)
- **RustChain ledger anchor**: epoch 213, tx
  `b8ca23e722c2104f327e7fd9e5da5b29806b38ce2803c0d8876427f7de2d294d`
- **Verify (public)**: <https://rustchain.org/bcos/verify/BCOS-5664a2af>
  returns `verified: true`, `commitment_valid: true`, `anchored_epoch: 213`

### What "anchored" means here, precisely

The certificate is recorded two ways, both publicly verifiable at the URL above:

1. In the RustChain node's BCOS attestation registry, whose verify endpoint
   recomputes the commitment from the stored report and confirms it matches.
2. As a permanent entry in the RustChain ledger (the chain's transaction
   history the block explorer reads), written by `/api/v1/bcos/anchor`. It is a
   zero-value memo entry (no RTC moves, no balance or supply impact) carrying
   the commitment, stamped at epoch 213.

Honest scope: RustChain is a Proof-of-Antiquity ledger, not Bitcoin or Ethereum.
The anchor is a real, permanent, publicly verifiable ledger entry on RustChain;
it is not a transaction on a public-market chain, and this file does not claim
that.

## Self-assessment (reproducible)

Score: **85 / 100**, L1 met.

| Check (max) | Score | Notes |
|-------------|-------|-------|
| Static analysis (20) | 20 | semgrep run; all 21 findings fixed or justified inline |
| Vulnerability scan (25) | 25 | no third-party dependency manifests, so nothing declared can be vulnerable |
| Test evidence (10) | 10 | `tests/run_all_tests.sh` runs every app's host self-test; CI builds all 8 apps |
| SBOM completeness (10) | 7 | real CycloneDX SBOM at `sbom.json` listing the actual components |
| License compliance (20) | 13 | SPDX MIT on all our own code; capped by the vendored third-party AmiSSL SDK |
| Dependency freshness (5) | 5 | no dependency manifests, so nothing can be out of date |
| Review attestation (10) | 5 | L1 tier (agent plus human review) |

The score is reproducible: the BCOS engine scans this project's own declared
dependencies (of which the C code has none via any package manager) rather than
the Python environment of whatever machine runs the scanner, so it reads 85 from
any host, not just a specially cleaned one.

### Why license compliance is capped at 13/20

The vendored AmiSSL SDK under `common/amissl-sdk/` is 172 upstream OpenSSL/AmiSSL
headers (Apache-2.0), left intentionally untagged: we did not author them and
tagging them MIT would misstate their license. That holds SPDX coverage at ~37%
of all code files even though every one of our own files is tagged.

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

An earlier version of this file claimed the repository "is certified" and
"anchored to the RustChain ledger" before any grade had been earned and with
nothing recorded anywhere. That was false and was corrected. The claim is now
actually true and backed: a reproducible L1 grade (85/100), attested to the
RustChain node registry and anchored as a real ledger entry (epoch 213, tx
above), all publicly verifiable at the rustchain.org URL. The earlier two gaps
(rustchain.org not serving the BCOS routes, and no ledger anchor endpoint) have
both been closed.

- Organization: [Elyan Labs](https://elyanlabs.ai)
- Chain: [RustChain](https://rustchain.org) (Proof of Antiquity)
- Engine: BCOS v2, free and open source (MIT)
