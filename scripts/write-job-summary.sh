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

if jq -e '.dependency != null' "$result_file" >/dev/null; then
  dependency="$(jq -r '.dependency.name' "$result_file")"
  from="$(jq -r '.dependency.from' "$result_file")"
  to="$(jq -r '.dependency.to' "$result_file")"
  {
    echo
    echo "### Dependency"
    echo
    echo "\`$dependency\`: \`$from\` -> \`$to\`"
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

message="$(jq -r '.message // empty' "$result_file")"
if [[ -n "$message" ]]; then
  {
    echo
    echo "### Message"
    echo
    echo "\`$message\`"
  } >> "$summary_file"
fi
