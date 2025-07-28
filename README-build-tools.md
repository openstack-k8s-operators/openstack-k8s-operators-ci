# OpenStack K8s Operators CI Build Tools Container

This directory contains the Dockerfile and build script for creating a container image with all the required build tools pre-installed for OpenStack K8s operators development and CI.

## Files

- `Dockerfile.build-tools` - Dockerfile that installs all required tools with exact versions from the Makefile
- `build-tools-image.sh` - Script to build and optionally push the container image
- `README-build-tools.md` - This documentation file

## Pre-installed Tools

The container image includes all tools with their exact versions as specified in the openstack-operator Makefile:

| Tool | Version | Purpose |
|------|---------|---------|
| Go | 1.21.0 | Go toolchain |
| kustomize | v5.5.0 | Kubernetes YAML templating |
| kubectl-kuttl | 0.17.0 | Kubernetes test tool |
| operator-sdk | v1.31.0 | Operator development toolkit |
| golangci-lint | v1.59.1 | Go linting |
| yq | latest | YAML/JSON processor |
| oc | 4.16.0 | OpenShift CLI |
| opm | v1.29.0 | Operator package manager |
| jq | system | JSON processor (system package) |
| skopeo | system | Container image utility (system package) |
| file | system | File type identification (system package) |

**Note:** Tools requiring `go install` compilation are not pre-installed to keep the image lightweight. These can be installed at runtime if needed:
- controller-gen (v0.14.0)
- crd-to-markdown (v0.0.3)
- envtest (c7e1dc9b)
- ginkgo (latest)
- operator-lint (v0.3.0)

All tools are installed in `/tmp/workspace/bin` and are available in the PATH.

## Building the Image

### Using the build script (recommended)

```bash
# Build with default settings
./build-tools-image.sh

# Build and push to registry
./build-tools-image.sh --tag v1.0.0 --push

# Build with custom image name
./build-tools-image.sh --image-name quay.io/myorg/build-tools --tag latest

# See all options
./build-tools-image.sh --help
```

### Using podman directly

```bash
podman build -f Dockerfile.build-tools -t quay.io/openstack-k8s-operators/openstack-k8s-operators-ci-build-tools:latest .
```

## Using the Image

### In GitHub Actions

Update your workflow to use the custom image:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: quay.io/openstack-k8s-operators/openstack-k8s-operators-ci-build-tools:latest
      options: --user root
    
    env:
      CUSTOM_TOOLS_PATH: /tmp/workspace/bin
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
    
    - name: Run make commands
      env:
        PATH: ${{ env.CUSTOM_TOOLS_PATH }}:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        LOCALBIN: ${{ env.CUSTOM_TOOLS_PATH }}
        GOTOOLCHAIN: local
      run: |
        cd $GITHUB_WORKSPACE
        make manifests generate
        make test
```

### Testing locally

```bash
# Run interactive shell
podman run --rm -it quay.io/openstack-k8s-operators/openstack-k8s-operators-ci-build-tools:latest

# Check installed tools
podman run --rm quay.io/openstack-k8s-operators/openstack-k8s-operators-ci-build-tools:latest \
  bash -c "echo 'Installed tools:' && ls -la /tmp/workspace/bin"

# Run a specific command
podman run --rm -v $(pwd):/workspace \
  quay.io/openstack-k8s-operators/openstack-k8s-operators-ci-build-tools:latest \
  bash -c "cd /workspace && make manifests"
```

## Updating Tool Versions

When tool versions are updated in the Makefile:

1. Update the corresponding `ENV` variables in `Dockerfile.build-tools`
2. Rebuild the image: `./build-tools-image.sh --tag vX.Y.Z --push`
3. Update the `custom_image` input in your GitHub Actions workflows

## Directory Structure

The container uses the following directory structure:

- `/tmp/workspace/bin/` - All tools installed here
- Repository checkout uses default GitHub Actions workspace
- Tools are added to PATH per-step to avoid conflicts with system tools
- Commands run in the repository root (default GitHub Actions behavior)

**Important:** 
- Tools are added to PATH explicitly with full system paths: `PATH: ${{ env.CUSTOM_TOOLS_PATH }}:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`
- Override LOCALBIN to use pre-installed tools: `LOCALBIN: ${{ env.CUSTOM_TOOLS_PATH }}`
- Use local Go toolchain: `GOTOOLCHAIN: local` to prevent downloading Go versions
- Repository operations use `cd $GITHUB_WORKSPACE` to ensure commands run in the checked out repository
- Git safe directory must be configured: `git config --global --add safe.directory $GITHUB_WORKSPACE`
- This prevents Makefile from downloading tools/Go and uses pre-installed versions instead
