# openstack-k8s-operators-ci

## Image Build Status

[Post merge image build status](docs/image-build-status.md) for all operators across main, 18-stable, and 18.0-fr6 branches.

## Dependency PR Dashboard

[Dependency PR dashboard](docs/dependency-pr-dashboard.md) with search queries for tracking force-bump and Renovate PRs across all branches.

## Description
Common scripts and tools for the openstack-k8s-operators CI that can be used inside or outside of any CI platform.

## Test Coverage
The following tests are currently available to be run:
- **lint**
	- Source: `test-runner/golint.sh`
- **vet**
	- Source: `test-runner/govet.sh`
- **unit**
	- Source: `test-runner/gotest.sh`
