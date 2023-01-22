#!/bin/bash
set -ex

# Install kuttl
if [[ ! -f /usr/local/bin/kubectl-kuttl ]]; then
    wget -O /usr/local/bin/kubectl-kuttl https://github.com/kudobuilder/kuttl/releases/download/v0.9.0/kubectl-kuttl_0.9.0_linux_x86_64
    chmod +x /usr/local/bin/kubectl-kuttl
fi


OPERATOR=$(echo ${1} | cut -d '-' -f1)
export ${OPERATOR^^}_IMG=$2/$1-index:$3
echo "make ${OPERATOR}_kuttl"

cd $HOME
rm -rf install_yamls
git clone https://github.com/openstack-k8s-operators/install_yamls.git
cd $HOME/install_yamls
make crc_storage
sleep 20
make ${OPERATOR}_kuttl
