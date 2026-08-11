#!/bin/bash
#
# ruleset.sh - Create a GitHub branch protection ruleset via the GitHub API.
#
# Creates a repository ruleset named "Minimum required Branch Protection"
# that protects the "main" and "18.0-fr*" branches by:
#   - blocking branch deletion
#   - blocking non-fast-forward pushes
#   - requiring a pull request with at least 1 approving review and
#     code owner review before merging
#
# Prerequisites:
#   - GitHub CLI (`gh`) installed: https://cli.github.com/
#   - Authenticated with sufficient permissions to manage repo rulesets
#     (repo admin), e.g. `gh auth login`
#   - Run from within a local clone of the target repository, so `gh`
#     can resolve the `:owner/:repo` placeholders in the API path.
#     Alternatively, edit the script to hardcode `/repos/<owner>/<repo>/rulesets`
#     to target a specific repo regardless of the current directory.
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
# To target different branches or rules, edit the JSON payload below
# (see the GitHub REST API docs for repository rulesets).

gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/:owner/:repo/rulesets \
  --input - <<< '{
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
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": true,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    }
  ]
}'
