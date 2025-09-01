FROM registry.ci.openshift.org/openshift/release:rhel-9-release-golang-1.24-openshift-4.21
RUN yum update -y && yum install -y python3.11 python3.11-pip
RUN alternatives --set python3 /usr/bin/python3.11
RUN pip3 install pre-commit
