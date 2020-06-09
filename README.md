# openstack-k8s-operators-ci

## Description
Common scripts and tools for the openstack-k8s-operators CI that
can be used inside or outside of any CI platform. 

## Coverage
The following tests are currently available to be run:
- **lint**
	- Source: `test-runner/golint.sh`
- **vet**
	- Source: `test-runner/govet.sh`
- **unit**
	- Source: `test-runner/gotest.sh`
