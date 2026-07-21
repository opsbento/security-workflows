#!/usr/bin/env bash
set -euo pipefail

findings_file="${1:?findings json path is required}"

if [[ ! -f "$findings_file" ]]; then
  echo "No dependency scan findings file was produced."
  exit 0
fi

count="$(jq '.matches | length' "$findings_file")"
echo "Dependency scan result"
echo "matches=$count"

if [[ "$count" == "0" ]]; then
  echo "No vulnerabilities found."
  exit 0
fi

echo "vulnerabilities:"
jq -r '
  def rank($s):
    ($s | ascii_downcase) as $v
    | if $v == "critical" then 4
      elif $v == "high" then 3
      elif $v == "medium" then 2
      elif $v == "low" then 1
      else 0
      end;
  .matches
  | sort_by(rank(.vulnerability.severity), .artifact.name, .vulnerability.id)
  | reverse
  | .[:50]
  | .[]
  | "- \(.artifact.name)@\(.artifact.version) \(.vulnerability.id) \(.vulnerability.severity) fixed=\((.vulnerability.fix.versions // []) | join(","))"
' "$findings_file"
