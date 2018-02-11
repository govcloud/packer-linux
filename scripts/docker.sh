#!/bin/bash -eux

if [[ $DOCKER  =~ true || $DOCKER =~ 1 || $DOCKER =~ yes ]]; then
    sudo yum install –y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum-config-manager –enable docker-ce-edge
    sudo yum makecache fast
    yum -y install docker-ce
    systemctl start docker
    systemctl enable docker
    sudo usermod -aG docker $(whoami)
fi
