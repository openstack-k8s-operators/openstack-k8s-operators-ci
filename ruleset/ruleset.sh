#!/bin/bash
#
# ruleset.sh - Create or update a GitHub branch protection ruleset.
#
# Creates (or updates) a repository ruleset named
# "Minimum required Branch Protection" that protects the "main" and
# "18.0-fr*" branches by:
#   - blocking branch deletion
#   - blocking non-fast-forward pushes
#   - requiring a pull request before merging
#
# GitHub review approvals and CODEOWNERS reviews are intentionally not
# required. Merge gating for openstack-k8s-operators repos is handled by
# Prow Tide via the `approved` and `lgtm` labels (from `/approve` and
# `/lgtm`, plus OWNERS files). Tide merges through the GitHub API and
# does not submit a native GitHub "Approve" review.
#
# A ruleset with required_approving_review_count >= 1 causes Tide to
# fail with:
#   PR is unmergable. Do the Tide merge requirements match the GitHub
#   settings for the repo? Repository rule violations found
#   At least 1 approving review is required by reviewers with write
#   access.
#
# Prerequisites:
#   - GitHub CLI (`gh`) installed: https://cli.github.com/
#   - Authenticated with sufficient permissions to manage repo rulesets
#     (repo admin), e.g. `gh auth login`
#   - Run from within a local clone of the target repository, so `gh`
#     can resolve the `:owner/:repo` placeholders in the API path.
#     Alternatively, edit the script to hardcode
#     `/repos/<owner>/<repo>/rulesets` to target a specific repo
#     regardless of the current directory.
#
# How to use:
#   1. cd into a local clone of the target repository, with its "origin"
#      remote (or another remote `gh` recognizes) pointing at the
#      GitHub repo you want to protect, e.g.:
#        cd ~/go/src/github.com/openstack-k8s-operators/<repo-name>
#        git remote -v   # confirm origin -> github.com/<owner>/<repo>
#   2. Ensure you're authenticated with `gh` as a user with admin
#      rights on that repo:
#        gh auth status
#   3. Run this script from within that directory:
#        /path/to/ruleset.sh
#
# `gh api` resolves the `:owner/:repo` placeholders in the API path
# from the current directory's git remote, so the script must be run
# from inside the target repo's clone (not from this ruleset/ directory,
# unless that happens to be the repo you want to protect).
#
# If a ruleset with this name already exists, it is updated in place
# (PUT) instead of created (POST).
#
# To target different branches or rules, edit the JSON payload below
# (see the GitHub REST API docs for repository rulesets).

set -euo pipefail

RULESET_NAME="Minimum required Branch Protection"

PAYLOAD=$(cat <<'EOF'
{
  "name": "Minimum required Branch Protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": [
        "refs/heads/main",
        "refs/heads/18.0-fr*"
      ],
      "exclude": []
    }
  },
  "bypass_actors": [],
  "rules": [
    {
      "type": "deletion"
    },
    {
      "type": "non_fast_forward"
    },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    }
  ]
}
EOF
)

RULESET_ID=$(gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/:owner/:repo/rulesets \
  --jq ".[] | select(.name==\"${RULESET_NAME}\") | .id" | head -n1)

if [ -n "${RULESET_ID}" ]; then
    echo "Updating existing ruleset id=${RULESET_ID}" >&2
    gh api \
      --method PUT \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "/repos/:owner/:repo/rulesets/${RULESET_ID}" \
      --input - <<< "${PAYLOAD}"
else
    echo "Creating ruleset" >&2
    gh api \
      --method POST \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      /repos/:owner/:repo/rulesets \
      --input - <<< "${PAYLOAD}"
fi
