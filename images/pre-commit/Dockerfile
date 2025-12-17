FROM registry.ci.openshift.org/openshift/release:rhel-9-release-golang-1.22-openshift-4.18
RUN yum update -y && yum install -y python3.12 python3.12-pip
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
RUN pip3.12 install pre-commit
