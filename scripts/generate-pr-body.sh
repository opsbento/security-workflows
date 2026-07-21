#!/usr/bin/env bash
set -euo pipefail

result_file="${1:?result json path is required}"

dependency="$(jq -r '.dependency.name' "$result_file")"
from="$(jq -r '.dependency.from' "$result_file")"
to="$(jq -r '.dependency.to' "$result_file")"
removed="$(jq -r '.verification.target_findings_removed' "$result_file")"
new_critical="$(jq -r '.verification.new_critical_findings' "$result_file")"
files_valid="$(jq -r '.verification.dependency_files_valid' "$result_file")"

cat <<BODY
## Automated dependency remediation

Updates \`$dependency\` from \`$from\` to \`$to\`.

### Vulnerabilities addressed

| Advisory | Severity |
|---|---:|
BODY

jq -r '.vulnerabilities[]? | "| `\(.id)` | \(.severity) |"' "$result_file"

cat <<BODY

### Why this version?

\`$to\` is the minimum available version selected by remediation-core that resolves all selected findings under the configured update policy.

### Verification

- Target findings removed: \`$removed\`
- New Critical findings: \`$new_critical\`
- Dependency files valid: \`$files_valid\`

<!-- remediation-core:$(jq -c '{ecosystem, dependency, vulnerabilities}' "$result_file") -->
BODY
