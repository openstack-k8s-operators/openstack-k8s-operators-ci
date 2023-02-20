FROM centos/centos:stream9
USER root
RUN dnf install -y gcc git jq make python3 python3-pip python-setuptools python-requests
RUN git clone https://git.openstack.org/openstack/tripleo-repos && \
    pushd tripleo-repos && \
    python3 setup.py install && \
    popd && \
    /usr/local/bin/tripleo-repos current-tripleo-dev

RUN dnf update -y && \
    dnf install -y python3-tempestconf openstack-tempest openstack-tempest-all && \
    dnf clean all && \
    rm -rf /var/cache/dnf/*

RUN git clone https://git.openstack.org/openstack/openstack-tempest-skiplist && \
    pushd openstack-tempest-skiplist && \
    python3 -m pip install . && \
    popd
RUN curl -s -L https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz | tar xvzf - -C /usr/local/bin oc
RUN chmod +x /usr/local/bin/oc
