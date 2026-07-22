#!/usr/bin/env bash
set -euo pipefail

result_file="${1:?result json path is required}"
summary_file="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

if [[ ! -f "$result_file" ]]; then
  {
    echo "## Dependency remediation"
    echo
    echo "No remediation result was produced."
  } >> "$summary_file"
  exit 0
fi

status="$(jq -r '.status' "$result_file")"
ecosystem="$(jq -r '.ecosystem // "n/a"' "$result_file")"
directory="$(jq -r '.directory // "n/a"' "$result_file")"

{
  echo "## Dependency remediation"
  echo
  echo "| Field | Value |"
  echo "|---|---|"
  echo "| Status | \`$status\` |"
  echo "| Ecosystem | \`$ecosystem\` |"
  echo "| Directory | \`$directory\` |"
} >> "$summary_file"

if jq -e '(.dependencies // [ .dependency ] | map(select(. != null)) | length) > 0' "$result_file" >/dev/null; then
  {
    echo
    echo "### Dependencies"
    echo
    echo "| Dependency | From | To |"
    echo "|---|---:|---:|"
    jq -r '(.dependencies // [ .dependency ] | map(select(. != null)))[] | "| `\(.name)` | `\(.from)` | `\(.to)` |"' "$result_file"
  } >> "$summary_file"
fi

if jq -e '.vulnerabilities | length > 0' "$result_file" >/dev/null; then
  {
    echo
    echo "### Vulnerabilities addressed"
    echo
    echo "| Advisory | Severity |"
    echo "|---|---:|"
    jq -r '.vulnerabilities[] | "| `\(.id)` | \(.severity) |"' "$result_file"
  } >> "$summary_file"
fi

if jq -e '.manual_reviews | length > 0' "$result_file" >/dev/null; then
  {
    echo
    echo "### Manual review"
    echo
    echo "| Dependency | Reason | Checked | Last candidate | Target removed | Remaining threshold | New threshold |"
    echo "|---|---|---:|---:|---:|---:|---:|"
    jq -r '.manual_reviews[] | "| `\(.dependency)` | \(.reason) | `\(.candidates_checked // 0)` | `\(.last_candidate // "n/a")` | `\(.target_findings_removed // "n/a")` | `\(.remaining_threshold_findings // 0)` | `\(.new_threshold_findings // 0)` |"' "$result_file"
  } >> "$summary_file"
fi

message="$(jq -r '.message // empty' "$result_file")"
if [[ -n "$message" ]]; then
  {
    echo
    echo "### Message"
    echo
    echo "\`$message\`"
  } >> "$summary_file"
fi

if jq -e '.verification != null' "$result_file" >/dev/null; then
  {
    echo
    echo "### Verification"
    echo
    echo "| Check | Value |"
    echo "|---|---:|"
    jq -r '"| Target findings removed | `\(.verification.target_findings_removed)` |"' "$result_file"
    jq -r '"| Remaining threshold findings | `\(.verification.remaining_threshold_findings // 0)` |"' "$result_file"
    jq -r '"| New threshold findings | `\(.verification.new_threshold_findings // 0)` |"' "$result_file"
    jq -r '"| New Critical findings | `\(.verification.new_critical_findings)` |"' "$result_file"
    jq -r '"| Dependency files valid | `\(.verification.dependency_files_valid)` |"' "$result_file"
  } >> "$summary_file"
fi
