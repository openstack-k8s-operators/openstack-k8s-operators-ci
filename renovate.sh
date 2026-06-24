# This is what we use to run a self-hosted Renovate to create github PR's.
# Running self-hosted is required to be able to execute the postUpgradeCommands
#
# Required environment variables (set in ~/.bash_profile on the runner):
#   RENOVATE_GITHUB_APP_ID          - GitHub App ID
#   RENOVATE_GITHUB_INSTALLATION_ID - GitHub App Installation ID
#   RENOVATE_GITHUB_APP_KEY         - Path to GitHub App private key (.pem)
#
# See docs/renovate-github-app-setup.md for setup instructions.
set -v

while true
do
 log_dir="./logs"
 mkdir -p $log_dir
 find "$log_dir" -type f -name "*.log" -mtime +5 -exec rm -f {} \;

 echo "Pruning old images"
 podman image prune --force

 # NOTE: (dprince) openstack-operator requires skopeo (and wget for now)
 mkdir -p custom_renovate
 pushd custom_renovate
cat << EOF_CAT > Dockerfile
FROM renovate:latest
USER root
RUN apt-get update
RUN apt-get install -y skopeo wget file
USER ubuntu
EOF_CAT
 popd
 podman build --pull=always custom_renovate -t renovate:local

 # NOTE(gibi): The --update-not-scheduled causes that renovate
 # will only auto rebase its PRs during our pre-defined schedule
 # so it won't do rebase at every renovater run if the base
 # branch changes

 log_file="$log_dir/renovate_$(date +'%Y%m%d_%H%M%S').log"

 # Generate a GitHub App installation token (expires after 1 hour)
 RENOVATE_GITHUB_APP_TOKEN=$(podman run --rm \
   -v "${RENOVATE_GITHUB_APP_KEY}:/key.pem:ro,Z" \
   ghcr.io/mshekow/github-app-installation-token:latest \
   "${RENOVATE_GITHUB_APP_ID}" \
   "${RENOVATE_GITHUB_INSTALLATION_ID}" \
   "/key.pem")

 echo "Running Renovate..."
 podman run -e RENOVATE_TOKEN="${RENOVATE_GITHUB_APP_TOKEN}" -e BINDATA_GIT_ADD=true -e LOG_LEVEL=debug --rm \
 localhost/renovate:local \
 --git-author="OpenStack K8s CI <openstack-k8s@redhat.com>" \
 --update-not-scheduled=false \
 --allowed-post-upgrade-commands="^make manifests generate,^make bindata,^make gowork,^go mod tidy,^make tidy,^make force-bump,^git reset" \
 openstack-k8s-operators/openstack-operator \
 openstack-k8s-operators/lib-common \
 openstack-k8s-operators/infra-operator \
 openstack-k8s-operators/nova-operator \
 openstack-k8s-operators/keystone-operator \
 openstack-k8s-operators/mariadb-operator \
 openstack-k8s-operators/cinder-operator \
 openstack-k8s-operators/glance-operator \
 openstack-k8s-operators/manila-operator \
 openstack-k8s-operators/ironic-operator \
 openstack-k8s-operators/openstack-baremetal-operator \
 openstack-k8s-operators/horizon-operator \
 openstack-k8s-operators/octavia-operator \
 openstack-k8s-operators/neutron-operator \
 openstack-k8s-operators/ovn-operator \
 openstack-k8s-operators/heat-operator \
 openstack-k8s-operators/telemetry-operator \
 openstack-k8s-operators/designate-operator \
 openstack-k8s-operators/barbican-operator \
 openstack-k8s-operators/swift-operator \
 openstack-k8s-operators/test-operator \
 openstack-k8s-operators/watcher-operator \
 openstack-k8s-operators/openstack-k8s-operators-ci 2>&1 | tee $log_file

 echo "sleeping 60 minutes..."
 sleep 3600
done
