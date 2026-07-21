# Security Workflows

Centralized reusable GitHub workflows for dependency scanning and remediation.

This repository is responsible for provider orchestration only:

- checkout caller repositories;
- run pinned remediation-core;
- read `result.json`;
- create deterministic branches;
- commit dependency file changes;
- create or update Pull Requests;
- upload SBOM and scan artifacts;
- write GitHub job summaries.

It must not contain package-manager remediation logic or raw Grype parsing logic.

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
      remediation-core-ref: v0.1.0
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

## Compatibility

| Security Workflows | Remediation Core | Status |
| --- | --- | --- |
| v1.0.0 | v0.1.0 | Planned |

## Production Pinning

Release branches/tags should pin `remediation-core-ref` and `security-workflows-ref` to immutable tags or commit SHAs. The reusable workflow is prepared for that model through explicit ref inputs.
