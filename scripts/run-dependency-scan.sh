#!/usr/bin/env bash
set -euo pipefail

workdir="${1:-.}"
severity="${2:-high}"
reports="${3:-reports}"
source_name="${GITHUB_REPOSITORY:-workspace}"
source_version="${GITHUB_SHA:-workspace}"

mkdir -p "$reports"
syft "dir:$workdir" --source-name "$source_name" --source-version "$source_version" -o "syft-json=$reports/sbom.json"
syft "dir:$workdir" --source-name "$source_name" --source-version "$source_version" -o "cyclonedx-json=$reports/sbom.cdx.json"
grype "sbom:$reports/sbom.json" -o json > "$reports/findings.json"

if jq -e --arg severity "$severity" '
  def rank($s):
    ($s | ascii_downcase) as $v
    | if $v == "critical" then 4
      elif $v == "high" then 3
      elif $v == "medium" then 2
      elif $v == "low" then 1
      else 0
      end;
  (rank($severity)) as $minimum
  | any(.matches[]?; rank(.vulnerability.severity) >= $minimum)
' "$reports/findings.json" >/dev/null; then
  echo "discovered vulnerabilities at or above the severity threshold: $severity" >&2
  exit 2
fi
