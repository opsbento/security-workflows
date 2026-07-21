# Contributing

This repository owns GitHub workflow orchestration only. Keep package manager logic, scanner parsing, version resolution, dependency updates, and verification in remediation-core.

## Verification

Use GitHub Actions as the primary verification path. The intended end-to-end test is a caller repository that invokes `.github/workflows/dependency-remediation.yml`, downloads a pinned remediation-core CLI release, updates dependency files, and verifies that this repository creates or updates exactly one Pull Request.

Keep repeated workflow shell logic in `scripts/` so reusable workflows stay compact.
