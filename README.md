# openstack-k8s-operators-ci

[![Builder Toolbox](https://quay.io/repository/openstack-k8s-operators/builder-toolbox/status "Builder Toolbox")](https://quay.io/repository/openstack-k8s-operators/builder-toolbox)

## Description
Common scripts and tools for the openstack-k8s-operators CI that can be used inside or outside of any CI platform. 

## Builder Toolbox
When `openstack-k8s-builder-toolbox` is changed on master branch, CI will trigger a new build on the container image on [quay.io](https://quay.io/repository/openstack-k8s-operators/builder-toolbox?tab=info)

## Test Coverage
The following tests are currently available to be run:
- **lint**
	- Source: `test-runner/golint.sh`
- **vet**
	- Source: `test-runner/govet.sh`
- **unit**
	- Source: `test-runner/gotest.sh`
