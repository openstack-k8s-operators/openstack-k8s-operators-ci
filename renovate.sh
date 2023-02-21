# This is what we use to run a self-hosted Renovate to create github PR's.
# Running self-hosted is required to be able to execute the postUpgradeCommands
set -v
while true
do
 echo "Running Renovate..."
 podman run --rm \
 renovate/renovate \
 --token="${RENOVATE_TOKEN}" \
 --git-author="OpenStack K8s CI <openstack-k8s@redhat.com>" \
 --log-file-level=debug \
 --allowed-post-upgrade-commands="^make manifests generate,^make gowork,^go mod tidy" \
 openstack-k8s-operators/openstack-operator \
 openstack-k8s-operators/lib-common \
 openstack-k8s-operators/nova-operator \
 openstack-k8s-operators/keystone-operator \
 openstack-k8s-operators/mariadb-operator \
 openstack-k8s-operators/cinder-operator \
 openstack-k8s-operators/glance-operator \
 openstack-k8s-operators/placement-operator
 echo "sleeping 60 minutes..."
 sleep 3600
done
