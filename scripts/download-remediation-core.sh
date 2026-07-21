#!/usr/bin/env bash
set -euo pipefail

repo="${1:?remediation-core repository is required}"
version="${2:?remediation-core version is required}"
asset="${3:?remediation-core asset is required}"
output="${4:?output path is required}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

gh release download "$version" \
  --repo "$repo" \
  --pattern "$asset" \
  --dir "$tmpdir"

gh release download "$version" \
  --repo "$repo" \
  --pattern checksums.txt \
  --dir "$tmpdir"

expected_checksum="$(awk -v asset="$asset" '$2 == asset {print $1}' "$tmpdir/checksums.txt")"
if [[ -z "$expected_checksum" ]]; then
  echo "checksum for $asset not found in remediation-core release $version" >&2
  exit 1
fi

actual_checksum="$(sha256sum "$tmpdir/$asset" | awk '{print $1}')"
if [[ "$actual_checksum" != "$expected_checksum" ]]; then
  echo "checksum mismatch for $asset" >&2
  exit 1
fi

install -m 0755 "$tmpdir/$asset" "$output"
