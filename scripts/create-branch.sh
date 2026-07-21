#!/usr/bin/env bash
set -euo pipefail

result_file="${1:?result json path is required}"
prefix="${2:-remediation}"
closed_pr_policy="${3:-new-branch}"

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

base_branch="$(slug "$prefix")/$(slug "$ecosystem")/$(slug "$dependency")-$(slug "$target")"
branch="$base_branch"
branch_reason="using deterministic remediation branch"

if command -v gh >/dev/null 2>&1; then
  open_count="$(gh pr list --head "$base_branch" --state open --json number --jq 'length')"
  closed_count="$(gh pr list --head "$base_branch" --state closed --json number --jq 'length')"

  if [[ "$open_count" == "0" && "$closed_count" != "0" ]]; then
    case "$closed_pr_policy" in
      new-branch)
        branch="${base_branch}-run-${GITHUB_RUN_ID:-$(date +%s)}"
        branch_reason="closed remediation PR exists; using run-specific branch"
        ;;
      reuse-branch)
        branch="$base_branch"
        branch_reason="closed remediation PR exists; reusing deterministic branch"
        ;;
      fail)
        echo "closed remediation PR already exists for $base_branch" >&2
        exit 1
        ;;
      *)
        echo "unsupported closed PR policy: $closed_pr_policy" >&2
        exit 1
        ;;
    esac
  elif [[ "$open_count" != "0" ]]; then
    branch_reason="open remediation PR exists; refreshing deterministic branch"
  fi
fi

echo "$branch_reason: $branch" >&2
git switch --quiet -C "$branch"
echo "branch=$branch" >> "${GITHUB_OUTPUT:-/dev/null}"
printf '%s\n' "$branch"
