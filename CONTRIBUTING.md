# Contributing

This repository owns GitHub workflow orchestration only. Keep package manager logic, scanner parsing, version resolution, dependency updates, and verification in remediation-core.

## Verification

Use GitHub Actions as the primary verification path. The intended end-to-end test is a caller repository that invokes `.github/workflows/dependency-remediation.yml`, lets remediation-core update dependency files, and verifies that this repository creates or updates exactly one Pull Request.
