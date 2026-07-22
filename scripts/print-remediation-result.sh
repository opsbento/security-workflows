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

if jq -e '(.dependencies // [ .dependency ] | map(select(. != null)) | length) > 0' "$result_file" >/dev/null; then
  echo "dependencies:"
  jq -r '(.dependencies // [ .dependency ] | map(select(. != null)))[] | "- \(.name) \(.from) -> \(.to)"' "$result_file"
fi

if jq -e '.vulnerabilities | length > 0' "$result_file" >/dev/null; then
  echo "vulnerabilities:"
  jq -r '.vulnerabilities[] | "- \(.id) \(.severity)"' "$result_file"
fi

if jq -e '.manual_reviews | length > 0' "$result_file" >/dev/null; then
  echo "manual_reviews:"
  jq -r '.manual_reviews[] | "- \(.dependency): \(.reason) checked=\(.candidates_checked // 0) last=\(.last_candidate // "n/a") target_removed=\(.target_findings_removed // "n/a") remaining_threshold=\(.remaining_threshold_findings // 0) new_threshold=\(.new_threshold_findings // 0)"' "$result_file"
fi

if jq -e '.changed_files | length > 0' "$result_file" >/dev/null; then
  echo "changed_files:"
  jq -r '.changed_files[] | "- \(.)"' "$result_file"
fi

if jq -e '.verification != null' "$result_file" >/dev/null; then
  echo "verification:"
  jq -r '"- target_findings_removed=\(.verification.target_findings_removed)"' "$result_file"
  jq -r '"- remaining_threshold_findings=\(.verification.remaining_threshold_findings // 0)"' "$result_file"
  jq -r '"- new_threshold_findings=\(.verification.new_threshold_findings // 0)"' "$result_file"
  jq -r '"- new_critical_findings=\(.verification.new_critical_findings)"' "$result_file"
  jq -r '"- dependency_files_valid=\(.verification.dependency_files_valid)"' "$result_file"
fi

message="$(jq -r '.message // empty' "$result_file")"
if [[ -n "$message" ]]; then
  echo "message=$message"
fi
