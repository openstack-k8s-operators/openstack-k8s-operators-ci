FROM registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.18-openshift-4.12
RUN yum update -y && yum install -y git python39 python39-pip
RUN alternatives --set python3 /usr/bin/python3.9
RUN pip3 install pre-commit
