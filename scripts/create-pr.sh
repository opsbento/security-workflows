#!/usr/bin/env bash
set -euo pipefail

result_file="${1:?result json path is required}"
branch="${2:?branch name is required}"
labels="${3:-dependencies,security,automated-remediation}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dependency_count="$(jq -r '(.dependencies // [ .dependency ] | map(select(. != null)) | length)' "$result_file")"
if [[ "$dependency_count" == "1" ]]; then
  dependency="$(jq -r '(.dependencies // [ .dependency ] | map(select(. != null)))[0].name' "$result_file")"
  from="$(jq -r '(.dependencies // [ .dependency ] | map(select(. != null)))[0].from' "$result_file")"
  to="$(jq -r '(.dependencies // [ .dependency ] | map(select(. != null)))[0].to' "$result_file")"
  title="Update ${dependency} from ${from} to ${to}"
else
  title="Update ${dependency_count} dependencies"
fi
body_file="$(mktemp)"
"$script_dir/generate-pr-body.sh" "$result_file" > "$body_file"
label_args=()
if [[ -n "$labels" ]]; then
  label_args=(--label "$labels")
fi

existing_url="$(gh pr list --head "$branch" --state open --json url --jq '.[0].url // empty')"
if [[ -n "$existing_url" ]]; then
  echo "updating existing remediation Pull Request: $existing_url" >&2
  gh pr edit "$existing_url" --title "$title" --body-file "$body_file" >/dev/null
  if [[ -n "$labels" ]] && ! gh pr edit "$existing_url" --add-label "$labels" >/dev/null 2>&1; then
    echo "warning: could not add labels '$labels'; continuing without labels" >&2
  fi
  printf '%s\n' "$existing_url"
  exit 0
fi

echo "creating remediation Pull Request for branch: $branch" >&2
if ! pr_url="$(gh pr create \
  --head "$branch" \
  --base "${GITHUB_BASE_REF:-$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')}" \
  --title "$title" \
  --body-file "$body_file" \
  "${label_args[@]}" 2>&1)"; then
  if [[ -n "$labels" ]]; then
    echo "warning: could not create PR with labels '$labels'; retrying without labels" >&2
    if ! pr_url="$(gh pr create \
      --head "$branch" \
      --base "${GITHUB_BASE_REF:-$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')}" \
      --title "$title" \
      --body-file "$body_file" 2>&1)"; then
      echo "$pr_url" >&2
      if grep -qi "GitHub Actions is not permitted to create or approve pull requests" <<<"$pr_url"; then
        echo "GitHub Actions cannot create Pull Requests for this repository." >&2
        echo "Enable Settings > Actions > General > Workflow permissions > Allow GitHub Actions to create and approve pull requests, or pass a PAT as secrets.REMEDIATION_TOKEN from the caller workflow." >&2
      fi
      exit 1
    fi
  else
    echo "$pr_url" >&2
    if grep -qi "GitHub Actions is not permitted to create or approve pull requests" <<<"$pr_url"; then
      echo "GitHub Actions cannot create Pull Requests for this repository." >&2
      echo "Enable Settings > Actions > General > Workflow permissions > Allow GitHub Actions to create and approve pull requests, or pass a PAT as secrets.REMEDIATION_TOKEN from the caller workflow." >&2
    fi
    exit 1
  fi
fi

printf '%s\n' "$pr_url"
