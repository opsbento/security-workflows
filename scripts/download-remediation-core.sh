#!/usr/bin/env bash
set -euo pipefail

repo="${1:?remediation-core repository is required}"
version="${2:?remediation-core version is required}"
asset="${3:?remediation-core asset is required}"
output="${4:?output path is required}"

gh release download "$version" \
  --repo "$repo" \
  --pattern "$asset" \
  --output "$output"
chmod +x "$output"
