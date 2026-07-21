# Security Workflows

Centralized reusable GitHub workflows for dependency scanning and remediation.

This repository is responsible for provider orchestration only:

- checkout caller repositories;
- download and run pinned remediation-core CLI releases;
- read `result.json`;
- create deterministic branches;
- commit dependency file changes;
- create or update Pull Requests;
- upload SBOM and scan artifacts;
- write GitHub job summaries.

It must not contain package-manager remediation logic or raw Grype parsing logic.

## Current Runtime Model

Caller repositories invoke this repository as a reusable workflow. The workflow downloads the pinned `remediation-core` CLI release, verifies it against the release `checksums.txt`, installs Syft and Grype through shared helper scripts, runs the CLI against the caller checkout, then creates or updates a Pull Request when the result is `VERIFIED_UPDATE`.

## Reusable Remediation Workflow

Caller repositories can use a small workflow:

```yaml
name: Dependency Remediation

on:
  workflow_dispatch:
  schedule:
    - cron: "0 2 * * 1-5"

permissions:
  contents: write
  pull-requests: write

jobs:
  remediate:
    uses: opsbento/security-workflows/.github/workflows/dependency-remediation.yml@v1
```

Optional inputs:

```yaml
jobs:
  remediate:
    uses: opsbento/security-workflows/.github/workflows/dependency-remediation.yml@v1
    secrets:
      REMEDIATION_TOKEN: ${{ secrets.REMEDIATION_TOKEN }}
    with:
      working-directory: "."
      ecosystem: npm
      minimum-severity: high
      allow-major: false
      maximum-updates: 1
      remediation-core-version: v0.1.1
      security-workflows-ref: v1.0.0
```

Pull Request creation requires either:

- repository setting enabled: `Settings > Actions > General > Workflow permissions > Allow GitHub Actions to create and approve pull requests`; or
- a fine-grained PAT stored and passed as `REMEDIATION_TOKEN`.

## Pull Request Behavior

When remediation-core returns `VERIFIED_UPDATE`, the workflow:

1. creates a deterministic branch named `remediation/<ecosystem>/<dependency>-<target-version>`;
2. commits only files listed by remediation-core in `changed_files`;
3. creates or updates one open Pull Request for that branch;
4. uploads before/after SBOM and Grype reports.

No PR is created for `NO_FINDING`, `SKIPPED`, or `NEEDS_MANUAL_REVIEW`.

## remediation-core CLI

The workflow downloads a pinned remediation-core CLI release asset and verifies its SHA-256 checksum before execution. It does not checkout or build remediation-core source during caller repository runs.

Default asset:

```text
ghcr.io is not required.
GitHub Release: opsbento/remediation-core v0.1.1
Asset: remediate-linux-amd64
```

## Compatibility

| Security Workflows | Remediation Core | Status |
| --- | --- | --- |
| main | v0.1.1 | Active demo |
| v1.0.0 | v0.1.1 | Planned release |

## Production Pinning

Release branches/tags should pin `remediation-core-version`, `remediation-core-asset`, and `security-workflows-ref` to released versions. Production releases should also pin third-party actions to full commit SHAs.
