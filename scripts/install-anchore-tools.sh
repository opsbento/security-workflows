#!/usr/bin/env bash
set -euo pipefail

syft_version="${SYFT_VERSION:-1.48.0}"
grype_version="${GRYPE_VERSION:-0.116.0}"

case "$(uname -m)" in
  x86_64) platform="linux_amd64" ;;
  aarch64|arm64) platform="linux_arm64" ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

curl -fsSL "https://github.com/anchore/syft/releases/download/v${syft_version}/syft_${syft_version}_${platform}.tar.gz" \
  | sudo tar -xz -C /usr/local/bin syft
curl -fsSL "https://github.com/anchore/grype/releases/download/v${grype_version}/grype_${grype_version}_${platform}.tar.gz" \
  | sudo tar -xz -C /usr/local/bin grype
