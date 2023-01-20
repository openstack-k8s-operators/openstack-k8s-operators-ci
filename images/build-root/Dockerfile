FROM registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.18-openshift-4.12
USER root
RUN yum install -y gcc git jq make python39 python39-pip && \
yum clean all && rm -rf /var/cache/dnf/*
RUN alternatives --set python3 /usr/bin/python3.9
RUN pip3 install python-openstackclient yq
RUN curl -s -L "https://raw.githubusercontent.com/openstack-k8s-operators/install_yamls/master/devsetup/vars/default.yaml" -o default.yaml
RUN SDK_VERSION=$(cat ./default.yaml | yq -r ".sdk_version") \
      && curl -s -L "https://github.com/operator-framework/operator-sdk/releases/download/${SDK_VERSION}/operator-sdk_linux_amd64" -o operator-sdk
RUN chmod +x ./operator-sdk
RUN mv ./operator-sdk /usr/local/bin
RUN curl -s -L "https://github.com/operator-framework/operator-registry/releases/latest/download/linux-amd64-opm" -o opm
RUN chmod +x ./opm
RUN mv ./opm /usr/local/bin
RUN KUSTOMIZE_VERSION=$(cat ./default.yaml | yq -r ".kustomize_version") \
      && curl -s -L "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" | tar xvzf - -C /usr/local/bin kustomize
RUN chmod +x /usr/local/bin/kustomize
RUN curl -s -L "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz" | tar xvzf - -C /usr/local/bin oc
RUN chmod +x /usr/local/bin/oc
RUN rm ./default.yaml