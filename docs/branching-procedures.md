# Branching Procedures

This document describes how to use the "Create Feature Branches in Repos v1"
workflow for the different branching scenarios in the openstack-k8s-operators org.

Workflow location: `.github/workflows/create-release-branch-v1.yml`

## Branch model

```
main ──────────────────────────────────────────► (RHOSO 19)
  │
  ├── 19.0 (cut from main when ready)
  ├── 19.1 (cut from main when ready)
  │
  └── 18-stable ◄── features + bugs for RHOSO 18
        ├── 18.0-fr6 (bugs for MRs)
        ├── 18.0-fr7 (cut from 18-stable when ready)
        └── ...
```


## Scenarios

### Scenario 1: Create stable branch (one-time per major version)

Creates `18-stable` from `main` and bumps main to the next major version.
This is done once when development shifts to the next major version.

**Workflow inputs:**

| Input | Value | Notes |
|---|---|---|
| SOURCE_BRANCH | `main` | Default, branch from main |
| BRANCH_NAME | `18-stable` | The new stable branch name |
| NEW_VERSION | `19.0` | main becomes 19.0.0 (RHOSO 19) |
| FORCE_BUMP_BRANCHES | `["main", "18-stable", "18.0-fr6"]` | All active branches |
| DRY_RUN | `true` (first), then `false` | Always dry-run first |
| CREATE_RELEASE_BRANCHES | `true` | |
| UPDATE_OPENSTACK_OPERATOR | `true` | Bumps version on main |
| UPDATE_CI_WORKFLOWS | `true` | Updates force-bump matrix |
| RETAG_RABBITMQ_OPERATOR | `false` | Not needed for stable branch |

**What the workflow does:**
1. Creates `18-stable` branch from `main` in all repos listed in `feature_branch_repos.yaml`
2. Updates `BRANCH` variable in Makefile on `18-stable` to `18-stable`
3. Updates `default_images.yaml` on `18-stable` (openstack-operator only)
4. Updates `renovate.json` on `18-stable` to extend `18-stable.json5` instead of `default.json5`
5. Creates a PR on `main` in openstack-operator bumping `VERSION` to `19.0.0`
6. Creates a PR in openstack-k8s-operators-ci updating force-bump-branches matrix

**Manual prerequisite:**
- Create `18-stable.json5` in the `renovate-config` repo before running the workflow. Copy from `default.json5` and adjust dependency bounds for the RHOSO 18 OCP target.

See [Checklist](#checklist) and [Post-branching tasks](#post-branching-tasks-fr-branches).

### Scenario 2: Create feature branch for RHOSO 19 (from main)

Creates a new RHOSO 19 feature release branch from `main`. This is the
current model — same as what we did for FR6 and earlier.

**Workflow inputs:**

| Input | Value | Notes |
|---|---|---|
| SOURCE_BRANCH | `main` | Default, branch from main |
| BRANCH_NAME | `19.0` | The new FR branch name |
| NEW_VERSION | `19.1` | main becomes 19.1.0 |
| FORCE_BUMP_BRANCHES | `["main", "19.0", "18-stable", "18.0-fr6"]` | Add new branch, keep all active |
| DRY_RUN | `true` (first), then `false` | |
| CREATE_RELEASE_BRANCHES | `true` | |
| UPDATE_OPENSTACK_OPERATOR | `true` | |
| UPDATE_CI_WORKFLOWS | `true` | |
| RETAG_RABBITMQ_OPERATOR | `true` | |

**What the workflow does:**
1. Creates `19.0` branch from `main` in all repos
2. Updates `BRANCH` variable on `19.0`
3. Creates PR bumping main to `19.1.0`
4. Updates force-bump-branches matrix
5. Retags rabbitmq-cluster-operator index

See [Checklist](#checklist) and [Post-branching tasks](#post-branching-tasks-fr-branches).

### Scenario 3: Create feature branch for RHOSO 18 (from 18-stable)

Creates a new RHOSO 18 feature release branch from `18-stable`.

**Workflow inputs:**

| Input | Value | Notes |
|---|---|---|
| SOURCE_BRANCH | `18-stable` | Branch to create from |
| BRANCH_NAME | `18.0-fr7` | The new FR branch name |
| NEW_VERSION | `0.8` | 18-stable becomes 0.8.0 |
| FORCE_BUMP_BRANCHES | `["main", "18-stable", "18.0-fr7"]` | All active branches — replaces the previous list (drop fr6 if no longer active, include active 19.x branches if any) |
| DRY_RUN | `true` (first), then `false` | |
| CREATE_RELEASE_BRANCHES | `true` | |
| UPDATE_OPENSTACK_OPERATOR | `true` | Version bump PR targets 18-stable |
| UPDATE_CI_WORKFLOWS | `true` | |
| RETAG_RABBITMQ_OPERATOR | `true` | |

**What the workflow does:**
1. Creates `18.0-fr7` branch from `18-stable` in all repos
2. Updates `BRANCH` variable in Makefile on `18.0-fr7`
3. Creates a PR on `18-stable` in openstack-operator bumping `VERSION` to `0.8.0`
4. Updates force-bump-branches matrix

**Manual follow-up steps:**
- Verify CRD gate is active on the new FR branch

See [Checklist](#checklist) and [Post-branching tasks](#post-branching-tasks-fr-branches).

## Version numbering

Starting with RHOSO 19, the version aligns with the branch name.
RHOSO 18 keeps the legacy 0.x.0 numbering.

| Branch | VERSION | Example |
|---|---|---|
| main (RHOSO 19) | 19.x.0 | 19.0.0, 19.1.0, 19.2.0 |
| 19.N | inherited from main at branch time | 19.0.0, 19.1.0 |
| 18-stable | 0.x.0 (legacy) | 0.7.0, 0.8.0, 0.9.0 |
| 18.0-frN | inherited from 18-stable at branch time | |

## Removing old FR branches from force-bump

When an FR branch is no longer active (no more MRs planned), remove it from
the `FORCE_BUMP_BRANCHES` list in the next workflow run. The branch itself
stays in the repos for history.

## Checklist

Before running the workflow:
- [ ] Dry-run first (`DRY_RUN: true`)
- [ ] Verify `feature_branch_repos.yaml` is up to date
- [ ] Confirm version numbering with the team
- [ ] Check that `FORCE_BUMP_BRANCHES` includes all active branches
- [ ] For stable branches: create `<branch-name>.json5` in the `renovate-config` repo (copy from `default.json5`, adjust dependency bounds)

After running the workflow:
- [ ] Merge the openstack-operator version bump PR
- [ ] Merge the openstack-k8s-operators-ci force-bump PR
- [ ] Run a test force-bump to verify the new branch is included

## Post-branching tasks (FR branches)

### Prow CI jobs (openshift/release)

Prow job configs need to be updated for the new FR branch — jobs expect the
branch to be part of the job config file name.

Use the helper script to create the openshift/release PR:
```bash
./switch_prow_jobs_fr_branch.sh <old-fr> <new-fr>
# e.g. ./switch_prow_jobs_fr_branch.sh fr6 fr7
```
Script added via https://github.com/openstack-k8s-operators/openstack-k8s-operators-ci/pull/139

### Zuul

Add the new branch to the Zuul default branches config.
Example: https://gitlab.com/softwarefactory-project/config/-/merge_requests/118

### Validate container images

Verify that the following images exist in quay with the new FR branch tag
(e.g. `18.0-fr7-latest`):
- https://quay.io/repository/openstack-k8s-operators/openstack-baremetal-operator-agent?tab=tags
- https://quay.io/repository/openstack-k8s-operators/openstack-ansibleee-runner?tab=tags
- https://quay.io/repository/openstack-k8s-operators/openstack-must-gather?tab=tags

If images are missing, trigger the build workflow on the new branch.

### Integrity pipeline

Update the integrity pipeline to pull data-plane-adoption repo content from
the new FR branch (ci-framework-jobs repo on internal GitLab).
