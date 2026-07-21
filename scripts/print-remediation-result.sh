#!/usr/bin/env bash
set -euo pipefail

result_file="${1:?result json path is required}"

if [[ ! -f "$result_file" ]]; then
  echo "No remediation result was produced."
  exit 0
fi

echo "Remediation result"
echo "status=$(jq -r '.status' "$result_file")"
echo "ecosystem=$(jq -r '.ecosystem // "n/a"' "$result_file")"
echo "directory=$(jq -r '.directory // "n/a"' "$result_file")"

if jq -e '.dependency != null' "$result_file" >/dev/null; then
  jq -r '"dependency=\(.dependency.name) \(.dependency.from) -> \(.dependency.to)"' "$result_file"
fi

if jq -e '.vulnerabilities | length > 0' "$result_file" >/dev/null; then
  echo "vulnerabilities:"
  jq -r '.vulnerabilities[] | "- \(.id) \(.severity)"' "$result_file"
fi

if jq -e '.changed_files | length > 0' "$result_file" >/dev/null; then
  echo "changed_files:"
  jq -r '.changed_files[] | "- \(.)"' "$result_file"
fi

message="$(jq -r '.message // empty' "$result_file")"
if [[ -n "$message" ]]; then
  echo "message=$message"
fi
