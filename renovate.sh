# This is what we use to run a self-hosted Renovate to create github PR's.
# Running self-hosted is required to be able to execute the postUpgradeCommands
set -v
while true
do
 echo "Pruning old images"
 podman image prune --force

 # NOTE(gibi): The --update-not-scheduled casues that renovate
 # will only auto rebase its PRs during our pre-defined schedule
 # so it won't do rebase at every renovater run if the base
 # branch changes

 echo "Running Renovate..."
 podman run --rm --pull=always \
 renovate/renovate \
 --token="${RENOVATE_TOKEN}" \
 --git-author="OpenStack K8s CI <openstack-k8s@redhat.com>" \
 --update-not-scheduled=false \
 --allowed-post-upgrade-commands="^make manifests generate,^make gowork,^go mod tidy,^make tidy,^make force-bump,^git reset" \
 openstack-k8s-operators/openstack-operator \
 openstack-k8s-operators/lib-common \
 openstack-k8s-operators/infra-operator \
 openstack-k8s-operators/nova-operator \
 openstack-k8s-operators/keystone-operator \
 openstack-k8s-operators/mariadb-operator \
 openstack-k8s-operators/cinder-operator \
 openstack-k8s-operators/glance-operator \
 openstack-k8s-operators/placement-operator \
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
 openstack-k8s-operators/test-operator

 echo "sleeping 60 minutes..."
 sleep 3600
done
