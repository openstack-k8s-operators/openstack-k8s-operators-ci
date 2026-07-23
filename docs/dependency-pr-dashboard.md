# Dependency PR Dashboard

Search queries for tracking automated dependency update PRs across the
openstack-k8s-operators org.

## Force-bump PRs (openstack-dependency-bump)

The force-bump workflow creates PRs that bump cross-repo openstack-k8s-operators
dependencies (lib-common, service operator APIs). These are authored by
`github-actions[bot]` on branches named `openstack-dependency-bump/<branch>`.

### All open

[All open dependency bump PRs](https://github.com/pulls?q=is%3Apr+is%3Aopen+org%3Aopenstack-k8s-operators+author%3Aapp%2Fgithub-actions+head%3Aopenstack-dependency-bump)

### Per branch

| Branch | Query |
|--------|-------|
| main | [main](https://github.com/pulls?q=is%3Apr+is%3Aopen+org%3Aopenstack-k8s-operators+author%3Aapp%2Fgithub-actions+head%3Aopenstack-dependency-bump%2Fmain) |
| 18-stable | [18-stable](https://github.com/pulls?q=is%3Apr+is%3Aopen+org%3Aopenstack-k8s-operators+author%3Aapp%2Fgithub-actions+head%3Aopenstack-dependency-bump%2F18-stable) |
| 18.0-fr6 | [18.0-fr6](https://github.com/pulls?q=is%3Apr+is%3Aopen+org%3Aopenstack-k8s-operators+author%3Aapp%2Fgithub-actions+head%3Aopenstack-dependency-bump%2F18.0-fr6) |

### Including merged/closed

[All dependency bump PRs (any state)](https://github.com/pulls?q=is%3Apr+org%3Aopenstack-k8s-operators+author%3Aapp%2Fgithub-actions+head%3Aopenstack-dependency-bump)

## Renovate PRs

Renovate creates PRs for Go module updates, GitHub Actions digest pinning, and
other dependency updates. These are authored by `ospk8s-renovate[bot]` (the
GitHub App) on branches prefixed with `renovate/`.

### All open

[All open Renovate PRs](https://github.com/pulls?q=is%3Apr+is%3Aopen+org%3Aopenstack-k8s-operators+author%3Aapp%2Fospk8s-renovate)

### Per branch

| Branch | Query |
|--------|-------|
| main | [main](https://github.com/pulls?q=is%3Apr+is%3Aopen+org%3Aopenstack-k8s-operators+author%3Aapp%2Fospk8s-renovate+head%3Arenovate%2Fmain) |
| 18-stable | [18-stable](https://github.com/pulls?q=is%3Apr+is%3Aopen+org%3Aopenstack-k8s-operators+author%3Aapp%2Fospk8s-renovate+head%3Arenovate%2F18-stable) |
| 18.0-fr6 | [18.0-fr6](https://github.com/pulls?q=is%3Apr+is%3Aopen+org%3Aopenstack-k8s-operators+author%3Aapp%2Fospk8s-renovate+head%3Arenovate%2F18.0-fr6) |

### Including merged/closed

[All Renovate PRs (any state)](https://github.com/pulls?q=is%3Apr+org%3Aopenstack-k8s-operators+author%3Aapp%2Fospk8s-renovate)
