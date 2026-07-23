# openstack-k8s-operators-ci

Common scripts and tools for the openstack-k8s-operators CI that can be used inside or outside of any CI platform.

## Dashboards

- [Post merge image build status](docs/image-build-status.md) — build badges for all operators across active branches
- [Dependency PR dashboard](docs/dependency-pr-dashboard.md) — search queries for tracking force-bump and Renovate PRs

## Workflows

### Branching and releases

| Workflow | Trigger | Description |
|----------|---------|-------------|
| [Create Feature Branches in Repos v1](.github/workflows/create-release-branch-v1.yml) | `workflow_dispatch` | Creates release/stable branches across all repos, bumps versions, updates CI configs. See [branching procedures](docs/branching-procedures.md). |
| [Tag RabbitMQ Index Image](.github/workflows/rabbitmq-cluster-operator-index-feature-tag.yaml) | `workflow_dispatch` | Retags the RabbitMQ cluster operator index image for a feature release branch. |

### Dependency management

| Workflow | Trigger | Description |
|----------|---------|-------------|
| [Force bump branches](.github/workflows/force-bump-branches.yaml) | `workflow_call` | Bumps openstack-k8s-operators cross-repo dependencies on all active branches. |
| [Generate force-bump PR](.github/workflows/force-bump-pull-request.yaml) | `workflow_call` | Creates a PR with bumped dependencies for a single repo/branch. Called by force-bump-branches. |
| [Update Renovate baseBranchPatterns](.github/workflows/update-renovate-branches.yaml) | `workflow_dispatch` | Updates `baseBranchPatterns` in `renovate.json` on main across all repos. Run after creating a new stable branch. |

### CI pipelines (reusable)

| Workflow | Trigger | Description |
|----------|---------|-------------|
| [Operator image builder](.github/workflows/reusable-build-operator.yaml) | `workflow_call` | Builds and pushes operator container images. |
| [Golang lint, vet and unit test](.github/workflows/golangci-lint.yaml) | `workflow_call` | Go linting, vetting, and unit test pipeline. |
| [Add Label to PR](.github/workflows/label-pr.yaml) | `workflow_call` | Adds labels to pull requests. |

### Image builds

| Workflow | Trigger | Description |
|----------|---------|-------------|
| [Build Customized Tobiko Image](.github/workflows/build-custom-tobiko-image.yml) | `workflow_dispatch` | Builds a customized advanced image for Tobiko testing. |
| [Build Customized WNTP Image](.github/workflows/build-custom-wntp-image.yml) | `workflow_dispatch` | Builds a customized image for WNTP testing. |
| [Build NAT64 Appliance Image](.github/workflows/build-nat64-appliance.yml) | `workflow_dispatch` | Builds the NAT64 appliance image. |

### Status and reporting

| Workflow | Trigger | Description |
|----------|---------|-------------|
| [Update image build status page](.github/workflows/update-image-build-status.yaml) | `workflow_dispatch` | Regenerates the [image build status](docs/image-build-status.md) page with per-branch build badges for all operators. |

## Scripts

### Tools (`tools/`)

| Script | Description |
|--------|-------------|
| `tools/delete-branch.sh` | Deletes a branch from all repos in the org. Records commit SHAs for recovery. Dry-run by default, pass `--execute` to apply. |

### CI and release helpers

| Script | Description |
|--------|-------------|
| `switch_prow_jobs_fr_branch.sh` | Creates openshift/release Prow job configs for a new FR branch. Usage: `./switch_prow_jobs_fr_branch.sh <old-fr> <new-fr>` |
| `renovate.sh` | Runs self-hosted Renovate to create dependency update PRs. Requires GitHub App credentials. See [setup docs](docs/renovate-github-app-setup.md). |
| `stage_downstream_rebase.sh` | Stages downstream rebase for operator bundles against the Red Hat registry. |
| `build-tools-image.sh` | Builds the CI build-tools container image (`openstack-k8s-operators-ci-build-tools`). |
| `dockerfile_to_osbs.sh` | Converts Dockerfiles to OSBS format. |

### Test runners (`test-runner/`)

| Script | Description |
|--------|-------------|
| `test-runner/golint.sh` | Go lint checks |
| `test-runner/golangci.sh` | golangci-lint pipeline |
| `test-runner/govet.sh` | Go vet checks |
| `test-runner/gotest.sh` | Go unit tests |
| `test-runner/gofmt.sh` | Go format checks |

### Pre-commit hooks (`pre-commit-hooks/`)

| Script | Description |
|--------|-------------|
| `pre-commit-hooks/kuttl-single-test-assert.sh` | Validates that kuttl tests have a single test assertion per file. |
