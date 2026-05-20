#!/bin/bash
# Delete a branch from all repos in the openstack-k8s-operators org.
# Records the commit SHA of each branch before deletion for recovery.
#
# Usage:
#   ./delete-branch.sh <branch>              # dry-run (default)
#   ./delete-branch.sh <branch> --execute    # actually delete branches
#
# Prerequisites:
#   - gh CLI installed and authenticated (https://cli.github.com/)
#   - Authenticated user must have push access to the target repos
#
# To restore a deleted branch from the log file:
#   gh api --method POST "repos/openstack-k8s-operators/REPO/git/refs" \
#     -f ref="refs/heads/BRANCH" -f sha="COMMIT_SHA"

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <branch-name> [--execute]"
    echo ""
    echo "  <branch-name>   Branch to delete from all org repos"
    echo "  --execute       Actually delete (default is dry-run)"
    exit 1
fi

ORG="openstack-k8s-operators"
BRANCH="$1"

if [[ $# -ge 2 && "$2" != "--execute" ]]; then
    echo "Unknown option: $2" >&2
    exit 1
fi

EXECUTE=false
[[ "${2:-}" == "--execute" ]] && EXECUTE=true
LOGFILE="deleted-branch-${BRANCH}-$(date +%Y%m%d-%H%M%S).log"

# Protected branches — to delete these, edit this list in the script.
PROTECTED_PATTERNS=("main" "master" "[0-9]*.0-fr*")

for PATTERN in "${PROTECTED_PATTERNS[@]}"; do
    # shellcheck disable=SC2053
    if [[ "$BRANCH" == $PATTERN ]]; then
        echo "ERROR: '$BRANCH' matches protected pattern '$PATTERN'. Refusing to delete."
        echo "If you really need to delete it, remove it from PROTECTED_PATTERNS in this script."
        exit 1
    fi
done

if ! $EXECUTE; then
    echo "=== DRY RUN MODE (pass --execute to actually delete) ==="
    echo ""
else
    read -rp "Delete branch '$BRANCH' from ALL repos in $ORG? [y/N] " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo "Checking all repos in $ORG for branch '$BRANCH'..."
echo "# branch deletion log - $(date -Iseconds)" > "$LOGFILE"
echo "# repo,branch,commit_sha" >> "$LOGFILE"

FOUND=0
DELETED=0
ERRORS=0

REPOS=$(gh repo list "$ORG" --no-archived --limit 500 --json name --jq '.[].name' | sort)
TOTAL=$(echo "$REPOS" | wc -w)
CURRENT=0

for REPO in $REPOS; do
    CURRENT=$((CURRENT + 1))
    printf "\r  Checking repo %d/%d..." "$CURRENT" "$TOTAL"

    if ! SHA=$(gh api "repos/$ORG/$REPO/branches/$BRANCH" --jq '.commit.sha' 2>/dev/null); then
        continue
    fi

    if [[ -z "$SHA" || "$SHA" == "null" ]]; then
        continue
    fi

    printf "\r\033[K"

    FOUND=$((FOUND + 1))
    echo "$ORG/$REPO,$BRANCH,$SHA" >> "$LOGFILE"

    if $EXECUTE; then
        if ERR=$(gh api --method DELETE "repos/$ORG/$REPO/git/refs/heads/$BRANCH" 2>&1); then
            echo "  DELETED  $ORG/$REPO (was $SHA)"
            DELETED=$((DELETED + 1))
        else
            echo "  ERROR    $ORG/$REPO (failed to delete, was $SHA): $ERR"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo "  would delete  $ORG/$REPO/$BRANCH  ($SHA)"
    fi
done
printf "\r\033[K"

echo ""
echo "Found: $FOUND repos with '$BRANCH' branch"
if $EXECUTE; then
    echo "Deleted: $DELETED, Errors: $ERRORS"
else
    echo "Dry run — no branches deleted. Run with --execute to delete."
fi
echo "Commit log: $LOGFILE"

if [[ "$ERRORS" -gt 0 ]]; then
    exit 1
fi
