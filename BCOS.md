# BCOS - Beacon Certified Open Source (in progress)

This repository is **working toward** certification under the Beacon Certified
Open Source (BCOS) program by [Elyan Labs](https://elyanlabs.ai). It is **not
certified yet**: no on-chain anchoring has been performed, and the composite
score does not reproducibly clear the L1 threshold (see the note on the two
environment-dependent checks below). License: `MIT`.

## Current self-assessment

Real improvements have been made and verified. The checks that actually measure
this repository are strong:

| Check (max) | Score | Notes |
|-------------|-------|-------|
| Static analysis (20) | 20 | semgrep run; all 21 findings fixed or justified inline, nothing suppressed blindly |
| Test evidence (10) | 10 | top-level `tests/run_all_tests.sh` runs every app's host self-test; CI builds all 8 apps |
| License compliance (20) | 13 | SPDX MIT on all our own code; capped by the vendored third-party AmiSSL SDK (see below) |
| SBOM completeness (10) | 7 | real CycloneDX SBOM at `sbom.json` listing the actual components |
| Review attestation (10) | 5 | L1 tier (agent + human review) |
| Vulnerability scan (25) | see note | measures the scanner's Python env, not this repo |
| Dependency freshness (5) | see note | measures the scanner's Python env, not this repo |

**Composite score observed: 57 to 85 out of 100, depending on the environment the
scanner runs in.** The ~28-point swing is entirely the two checks below, so we do
not claim a passing L1 grade on that basis.

### Why two checks do not apply cleanly here

`vulnerability_scan` (pip-audit) and `dependency_freshness` (pip list --outdated)
audit the Python environment the scanner is invoked from. amigatools is C for
m68k; its only Python is a handful of host-side helper scripts that use the
standard library, so it has **zero third-party runtime dependencies**. Run the
scanner from a busy machine and these checks report that machine's unrelated
packages (for example 152 CVEs in `aiohttp`, which is pulled in by semgrep
itself, not by anything in this repo). Run it from a truly empty venv and they
report full marks. Neither is a fact about amigatools. We are not banking the
full-marks reading.

### Why license compliance is capped at 13/20

The vendored AmiSSL SDK under `common/amissl-sdk/` is 172 upstream OpenSSL/AmiSSL
headers (Apache-2.0), left intentionally untagged because we did not author them
and tagging them MIT would misstate their license. That holds SPDX coverage at
~37% of all code files even though every one of our own files is tagged. Raising
this would require the SDK gaining upstream SPDX headers or being removed from the
scanned tree, neither of which this repo controls.

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

## Verify it yourself

```bash
# scanner tools; run the engine from a clean venv so the two dependency
# checks measure THIS repo (which has no python deps) and not your machine
python3 -m venv /tmp/bcos-venv && . /tmp/bcos-venv/bin/activate
pip install semgrep pip-audit cyclonedx-bom pip-licenses
python3 bcos_engine.py /path/to/amigatools --tier L1 --json
```

## Honesty note

An earlier version of this file claimed the repository "is certified" and that a
commitment was "anchored to the RustChain ledger." Neither was true: no passing
grade had been earned and nothing was written on-chain. That claim was removed.
The badge and an on-chain commitment come back only when the score reproducibly
meets an L1 grade in a clean measurement, and only with your explicit go-ahead
for the on-chain write.

- Organization: [Elyan Labs](https://elyanlabs.ai)
- Chain: [RustChain](https://rustchain.org) (Proof of Antiquity)
- Engine: BCOS v2, free and open source (MIT)
