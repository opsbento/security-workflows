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
grype "sbom:$reports/sbom.json" --fail-on "$severity"
