FROM centos/centos:stream9
USER root
RUN dnf install -y gcc git jq make python3 python3-pip python-setuptools python-requests
RUN git clone https://github.com/openstack-k8s-operators/repo-setup && \
    pushd repo-setup && \
    python3 setup.py install && \
    popd && \
    /usr/local/bin/repo-setup current-podified -b antelope

RUN dnf update -y && \
    dnf install -y python3-tempestconf openstack-tempest openstack-tempest-all && \
    dnf clean all && \
    rm -rf /var/cache/dnf/*

# Latest commit from skiplist repo before get retired.
RUN git clone https://opendev.org/openstack/openstack-tempest-skiplist.git && \
    pushd openstack-tempest-skiplist && \
    git checkout ec349ebef6942b2343be4584f734559f33eae241 && \
    pip install . && \
    popd

RUN curl -s -L "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o yq
RUN chmod +x ./yq
RUN mv ./yq /usr/local/bin
RUN curl -s -L https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz | tar xvzf - -C /usr/local/bin oc
RUN chmod +x /usr/local/bin/oc
