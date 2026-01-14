#!/usr/bin/env bash

set -euo pipefail

out_dir=".github/scripts/out"
report_path="$out_dir/bulk-review.md"
lint_out="$out_dir/lint.out"
lint_rc_file="$out_dir/lint.rc"

mkdir -p "$out_dir"

pr_number=""
base_sha=""
head_sha=""

if [[ -n "${GITHUB_EVENT_PATH:-}" && -f "$GITHUB_EVENT_PATH" ]]; then
    pr_number=$(jq -r '.pull_request.number // .number // empty' "$GITHUB_EVENT_PATH")
    base_sha=$(jq -r '.pull_request.base.sha // empty' "$GITHUB_EVENT_PATH")
    head_sha=$(jq -r '.pull_request.head.sha // empty' "$GITHUB_EVENT_PATH")
fi

if [[ -z "$head_sha" ]]; then
    head_sha=$(git rev-parse HEAD)
fi

if [[ -z "$base_sha" ]]; then
    base_sha=$(git merge-base "$head_sha" HEAD^ 2>/dev/null || true)
fi

if [[ -z "$base_sha" ]]; then
    base_sha="$head_sha"
fi

set +e
LINT_STATUS_DIR="$out_dir" ./scripts/lint.sh >"$lint_out" 2>&1
lint_rc=$?
set -e

printf '%s\n' "$lint_rc" > "$lint_rc_file"

commit_list=$(git rev-list --reverse "$base_sha..$head_sha" 2>/dev/null || true)

{
    echo "## Bulk Review"
    echo
    if [[ -n "$pr_number" ]]; then
        echo "- PR: #$pr_number"
    fi
    echo "- Base: $base_sha"
    echo "- Head: $head_sha"
    echo
    echo "### Commits in this PR"
    if [[ -z "$commit_list" ]]; then
        echo "_No commits found between base and head._"
    else
        count=1
        while read -r sha; do
            short_sha=$(git rev-parse --short "$sha")
            subject=$(git log -1 --format=%s "$sha")
            echo "$count. \`$short_sha\` $subject"
            files=$(git diff-tree --no-commit-id --name-only -r "$sha")
            if [[ -z "$files" ]]; then
                echo "   - (no files)"
            else
                while read -r file; do
                    echo "   - $file"
                done <<< "$files"
            fi
            count=$((count + 1))
        done <<< "$commit_list"
    fi
    echo
    echo "### Lint results"
    echo "\`\`\`"
    if [[ -s "$lint_out" ]]; then
        cat "$lint_out"
    else
        echo "No lint output captured."
    fi
    echo "\`\`\`"
} > "$report_path"

exit 0
