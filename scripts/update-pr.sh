#!/usr/bin/env bash
set -euo pipefail

result_file="${1:?result json path is required}"
branch="${2:?branch name is required}"
labels="${3:-dependencies,security,automated-remediation}"

./.security-workflows/scripts/create-pr.sh "$result_file" "$branch" "$labels"
