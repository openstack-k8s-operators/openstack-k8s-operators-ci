#!/bin/bash

set -e

# Default values
IMAGE_NAME="quay.io/openstack-k8s-operators/openstack-k8s-operators-ci-build-tools"
TAG="latest"
PUSH=false
DOCKERFILE="Dockerfile.build-tools"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --image-name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --push)
            PUSH=true
            shift
            ;;
        --dockerfile)
            DOCKERFILE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --image-name NAME    Container image name (default: quay.io/openstack-k8s-operators/openstack-k8s-operators-ci-build-tools)"
            echo "  --tag TAG           Image tag (default: latest)"
            echo "  --push              Push image to registry after building"
            echo "  --dockerfile FILE   Dockerfile to use (default: Dockerfile.build-tools)"
            echo "  --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Build image with default settings"
            echo "  $0 --tag v1.0.0 --push              # Build and push with specific tag"
            echo "  $0 --image-name myregistry/tools     # Use custom image name"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"

echo "Building container image..."
echo "Image: ${FULL_IMAGE_NAME}"
echo "Dockerfile: ${DOCKERFILE}"
echo ""

# Build the image
podman build -f "${DOCKERFILE}" -t "${FULL_IMAGE_NAME}" .

echo ""
echo "✅ Build completed successfully!"
echo "Image: ${FULL_IMAGE_NAME}"

# Push if requested
if [[ "${PUSH}" == "true" ]]; then
    echo ""
    echo "Pushing image to registry..."
    podman push "${FULL_IMAGE_NAME}"
    echo "✅ Push completed successfully!"
fi

echo ""
echo "To test the image locally:"
echo "  podman run --rm -it ${FULL_IMAGE_NAME}"
echo ""
echo "To use in GitHub Actions workflow:"
echo "  custom_image: '${FULL_IMAGE_NAME}'" 