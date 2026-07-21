#!/usr/bin/env bash
set -euo pipefail

result_file="${1:?result json path is required}"
branch="${2:?branch name is required}"
labels="${3:-dependencies,security,automated-remediation}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dependency="$(jq -r '.dependency.name' "$result_file")"
from="$(jq -r '.dependency.from' "$result_file")"
to="$(jq -r '.dependency.to' "$result_file")"
title="Update ${dependency} from ${from} to ${to}"
body_file="$(mktemp)"
"$script_dir/generate-pr-body.sh" "$result_file" > "$body_file"

existing_url="$(gh pr list --head "$branch" --state open --json url --jq '.[0].url // empty')"
if [[ -n "$existing_url" ]]; then
  gh pr edit "$existing_url" --title "$title" --body-file "$body_file" --add-label "$labels" >/dev/null
  printf '%s\n' "$existing_url"
  exit 0
fi

gh pr create \
  --head "$branch" \
  --base "${GITHUB_BASE_REF:-$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')}" \
  --title "$title" \
  --body-file "$body_file" \
  --label "$labels"
