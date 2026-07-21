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
label_args=()
if [[ -n "$labels" ]]; then
  label_args=(--label "$labels")
fi

existing_url="$(gh pr list --head "$branch" --state open --json url --jq '.[0].url // empty')"
if [[ -n "$existing_url" ]]; then
  gh pr edit "$existing_url" --title "$title" --body-file "$body_file" >/dev/null
  if [[ -n "$labels" ]] && ! gh pr edit "$existing_url" --add-label "$labels" >/dev/null 2>&1; then
    echo "warning: could not add labels '$labels'; continuing without labels" >&2
  fi
  printf '%s\n' "$existing_url"
  exit 0
fi

if ! pr_url="$(gh pr create \
  --head "$branch" \
  --base "${GITHUB_BASE_REF:-$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')}" \
  --title "$title" \
  --body-file "$body_file" \
  "${label_args[@]}")"; then
  if [[ -n "$labels" ]]; then
    echo "warning: could not create PR with labels '$labels'; retrying without labels" >&2
    pr_url="$(gh pr create \
      --head "$branch" \
      --base "${GITHUB_BASE_REF:-$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')}" \
      --title "$title" \
      --body-file "$body_file")"
  else
    exit 1
  fi
fi

printf '%s\n' "$pr_url"
