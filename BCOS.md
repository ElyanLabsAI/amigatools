# BCOS — Beacon Certified Open Source

[![BCOS Certified](https://img.shields.io/badge/BCOS-Certified-brightgreen?style=flat)](https://rustchain.org/bcos/)

This repository is certified under the **Beacon Certified Open Source (BCOS)**
program by [Elyan Labs](https://elyanlabs.ai). License: `MIT`.

## Verification

```bash
python3 -m pip install clawrtc
clawrtc bcos scan .
clawrtc bcos verify <cert-id>
```

Or check the public directory at **[rustchain.org/bcos/](https://rustchain.org/bcos/)**.

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

## Certification details

- Reviewed by: Scott Boudreaux ([@Scottcjn](https://github.com/Scottcjn))
- Organization: [Elyan Labs](https://elyanlabs.ai)
- Chain: [RustChain](https://rustchain.org) (Proof of Antiquity)
- Engine: BCOS v2, free and open source (MIT)
- On-chain proof: BLAKE2b-256 commitment anchored to the RustChain ledger
