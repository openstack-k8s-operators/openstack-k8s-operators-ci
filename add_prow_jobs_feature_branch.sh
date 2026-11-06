#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 --template-branch <branch> --target-branch <branch> [--exclude-repo <repo>]..."
    echo "Example: $0 --template-branch 18-stable --target-branch 19.0-beta --exclude-repo architecture --exclude-repo repo-setup"
}

TEMPLATE_BRANCH=
TARGET_BRANCH=
EXCLUDED_REPOS=()
EXCLUDED_REPO_COUNT=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --template-branch)
            if [ "$#" -lt 2 ]; then
                usage >&2
                exit 1
            fi
            TEMPLATE_BRANCH=$2
            shift 2
            ;;
        --target-branch)
            if [ "$#" -lt 2 ]; then
                usage >&2
                exit 1
            fi
            TARGET_BRANCH=$2
            shift 2
            ;;
        --exclude-repo)
            if [ "$#" -lt 2 ]; then
                usage >&2
                exit 1
            fi
            EXCLUDED_REPOS+=("$2")
            EXCLUDED_REPO_COUNT=$((EXCLUDED_REPO_COUNT + 1))
            shift 2
            ;;
        *)
            usage >&2
            exit 1
            ;;
    esac
done

if [ -z "$TEMPLATE_BRANCH" ] || [ -z "$TARGET_BRANCH" ]; then
    usage >&2
    exit 1
fi

if [ "$TEMPLATE_BRANCH" = "$TARGET_BRANCH" ]; then
    echo "Template and target branches must differ" >&2
    exit 1
fi

mapfile -t SOURCE_FILES < <(
    find ci-operator/config/openstack-k8s-operators ci-operator/jobs/openstack-k8s-operators \
        -type f -print | grep -F -- "$TEMPLATE_BRANCH" || true
)
FILTERED_SOURCE_FILES=()
for SOURCE_FILE in "${SOURCE_FILES[@]}"; do
    EXCLUDE_FILE=false
    if [ "$EXCLUDED_REPO_COUNT" -gt 0 ]; then
        for EXCLUDED_REPO in "${EXCLUDED_REPOS[@]}"; do
            if [[ "$SOURCE_FILE" == */openstack-k8s-operators/"$EXCLUDED_REPO"/* ]]; then
                EXCLUDE_FILE=true
                break
            fi
        done
    fi
    if [ "$EXCLUDE_FILE" = false ]; then
        FILTERED_SOURCE_FILES+=("$SOURCE_FILE")
    fi
done

if [ "${#FILTERED_SOURCE_FILES[@]}" -eq 0 ]; then
    echo "No Prow config files found for template branch: $TEMPLATE_BRANCH" >&2
    exit 1
fi

echo "Copying Prow configs from template branch $TEMPLATE_BRANCH to target branch $TARGET_BRANCH"
if [ "$EXCLUDED_REPO_COUNT" -gt 0 ]; then
    printf 'Excluding repos without a target branch: %s\n' "${EXCLUDED_REPOS[*]}"
fi
for SOURCE_FILE in "${FILTERED_SOURCE_FILES[@]}"; do
    TARGET_FILE=${SOURCE_FILE//"$TEMPLATE_BRANCH"/"$TARGET_BRANCH"}
    if [ -e "$TARGET_FILE" ]; then
        echo "Target file already exists: $TARGET_FILE" >&2
        exit 1
    fi

    cp -- "$SOURCE_FILE" "$TARGET_FILE"
    TEMPLATE_BRANCH="$TEMPLATE_BRANCH" TARGET_BRANCH="$TARGET_BRANCH" perl -0pi -e 's/\Q$ENV{TEMPLATE_BRANCH}\E/$ENV{TARGET_BRANCH}/g' "$TARGET_FILE"
done

export CONTAINER_ENGINE=podman
make jobs
make ci-operator-config
