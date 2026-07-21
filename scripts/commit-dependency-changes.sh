#!/usr/bin/env bash
set -euo pipefail

result_file="${1:?result json path is required}"

dependency="$(jq -r '.dependency.name' "$result_file")"
from="$(jq -r '.dependency.from' "$result_file")"
to="$(jq -r '.dependency.to' "$result_file")"
mapfile -t files < <(jq -r '.changed_files[]?' "$result_file")

if [ "${#files[@]}" -eq 0 ]; then
  echo "No changed files listed in remediation result." >&2
  exit 1
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -- "${files[@]}"
git commit -m "fix(deps): update ${dependency} from ${from} to ${to}"
