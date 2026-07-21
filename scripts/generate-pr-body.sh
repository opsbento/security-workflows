#!/usr/bin/env bash
set -euo pipefail

result_file="${1:?result json path is required}"

removed="$(jq -r '.verification.target_findings_removed' "$result_file")"
new_critical="$(jq -r '.verification.new_critical_findings' "$result_file")"
files_valid="$(jq -r '.verification.dependency_files_valid' "$result_file")"
dependency_count="$(jq -r '(.dependencies // [ .dependency ] | map(select(. != null)) | length)' "$result_file")"
dependency_noun="dependency"
if [[ "$dependency_count" != "1" ]]; then
  dependency_noun="dependencies"
fi

cat <<BODY
## Automated dependency remediation

Updates $dependency_count $dependency_noun.

### Dependency updates

| Dependency | From | To |
|---|---:|---:|
BODY

jq -r '(.dependencies // [ .dependency ] | map(select(. != null)))[] | "| `\(.name)` | `\(.from)` | `\(.to)` |"' "$result_file"

cat <<BODY

### Vulnerabilities addressed

| Advisory | Severity |
|---|---:|
BODY

jq -r '.vulnerabilities[]? | "| `\(.id)` | \(.severity) |"' "$result_file"

cat <<BODY

### Why this version?

Each target version is the minimum available version selected by remediation-core that resolves the selected findings for that dependency under the configured update policy.

### Verification

- Target findings removed: \`$removed\`
- New Critical findings: \`$new_critical\`
- Dependency files valid: \`$files_valid\`

<!-- remediation-core:$(jq -c '{ecosystem, dependency, dependencies, vulnerabilities}' "$result_file") -->
BODY
