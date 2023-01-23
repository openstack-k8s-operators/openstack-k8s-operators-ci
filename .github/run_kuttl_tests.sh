#!/bin/bash
set -ex

# Install kuttl
if [[ ! -f /usr/local/bin/kubectl-kuttl ]]; then
    wget -O /usr/local/bin/kubectl-kuttl https://github.com/kudobuilder/kuttl/releases/download/v0.9.0/kubectl-kuttl_0.9.0_linux_x86_64
    chmod +x /usr/local/bin/kubectl-kuttl
fi


OPERATOR=$(echo ${1} | cut -d '-' -f1)
export ${OPERATOR^^}_IMG=$2/$1-index:$3

export ${OPERATOR^^}_REPO=https://github.com/$4.git
export ${OPERATOR^^}_BRANCH=$5

cd $HOME
rm -rf install_yamls
git clone https://github.com/openstack-k8s-operators/install_yamls.git
cd $HOME/install_yamls
# Sometimes it fails to find container-00 inside debug pod
# TODO: fix issue in install_yamls
n=0
retries=3
while true; do
  make crc_storage && break
  n=$((n+1))
  if (( n >= retries )); then
    echo "Failed to run 'make crc_storage' target. Aborting"
    exit 1
  fi
  sleep 10
done
sleep 20
make ${OPERATOR}_kuttl
