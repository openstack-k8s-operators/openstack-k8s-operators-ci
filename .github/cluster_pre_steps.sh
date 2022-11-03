#!/bin/bash
set -ex
oc whoami
for i in `oc get csr |grep Pending |awk '{print $1}'`; do oc adm certificate approve $i; done
sleep 30
