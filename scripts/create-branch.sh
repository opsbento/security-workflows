#!/usr/bin/env bash
set -euo pipefail

result_file="${1:?result json path is required}"
prefix="${2:-remediation}"

dependency="$(jq -r '.dependency.name' "$result_file")"
ecosystem="$(jq -r '.ecosystem' "$result_file")"
target="$(jq -r '.dependency.to' "$result_file")"

if [[ -z "$dependency" || "$dependency" == "null" || -z "$target" || "$target" == "null" ]]; then
  echo "remediation result does not contain dependency target" >&2
  exit 1
fi

slug() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//'
}

branch="$(slug "$prefix")/$(slug "$ecosystem")/$(slug "$dependency")-$(slug "$target")"
git switch -C "$branch"
echo "branch=$branch" >> "$GITHUB_OUTPUT"
printf '%s\n' "$branch"
