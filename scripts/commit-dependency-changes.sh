#!/usr/bin/env bash
set -euo pipefail

result_file="${1:?result json path is required}"

dependency_count="$(jq -r '(.dependencies // [ .dependency ] | map(select(. != null)) | length)' "$result_file")"
mapfile -t files < <(jq -r '.changed_files[]?' "$result_file")

if [ "${#files[@]}" -eq 0 ]; then
  echo "No changed files listed in remediation result." >&2
  exit 1
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -- "${files[@]}"
if [[ "$dependency_count" == "1" ]]; then
  dependency="$(jq -r '(.dependencies // [ .dependency ] | map(select(. != null)))[0].name' "$result_file")"
  from="$(jq -r '(.dependencies // [ .dependency ] | map(select(. != null)))[0].from' "$result_file")"
  to="$(jq -r '(.dependencies // [ .dependency ] | map(select(. != null)))[0].to' "$result_file")"
  git commit -m "fix(deps): update ${dependency} from ${from} to ${to}"
else
  git commit -m "fix(deps): update ${dependency_count} dependencies"
fi
