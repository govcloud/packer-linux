#!/usr/bin/groovy

// load pipeline functions
// Requires pipeline-github-lib plugin to load library from github

@Library('github.com/sylus/jenkins-pipeline@dev')

def pipeline = new io.estrado.Pipeline()
def label = "packer-linux-${UUID.randomUUID().toString()}"

podTemplate(label: label,
  envVars: [
    envVar(key: 'PACKER_VERSION', value: '1.2.0')
  ],
  containers: [
    containerTemplate(name: 'jnlp',
                      image: 'jenkins/jnlp-slave:3.16-1-alpine',
                      args: '${computer.jnlpmac} ${computer.name}',
                      workingDir: '/home/jenkins',
                      resourceRequestCpu: '200m',
                      resourceLimitCpu: '300m',
                      resourceRequestMemory: '256Mi',
                      resourceLimitMemory: '512Mi',
                      privileged: true),
    containerTemplate(name: 'docker',
                      image: 'docker:1.12.6',
                      command: 'cat',
                      ttyEnabled: true),
    containerTemplate(name: 'centos',
                      image: 'centos:centos7',
                      command: 'cat',
                      ttyEnabled: true),
  ],
  volumes:[
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
  ]) {

  node (label) {
    stage('Run shell') {

      //def pwd = pwd()
      //def inputFile = readFile('Jenkinsfile.json')
      //def config = new groovy.json.JsonSlurperClassic().parseText(inputFile)
      //println "pipeline config ==> ${config}"

      git 'https://github.com/govcloud/packer-linux.git'

      container('centos') {

        // Install deps
        sh 'yum install -y \
              unzip \
              tar \
              gzip \
              wget && \
            yum clean all && rm -rf /var/cache/yum/*'

        // Install virtualbox
        sh 'export VIRTUALBOX_VERSION=latest && \
            mkdir -p /opt/virtualbox && \
            cd /etc/yum.repos.d/ && \
            wget http://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo && \
            yum install -y \
              patch \
              libgomp \
              glibc-headers \
              glibc-devel \
              kernel-headers \
              kernel-PAE-devel \
              dkms && \
            yum -y groupinstall "Development Tools" && \
            if  [ "${VIRTUALBOX_VERSION}" = "latest" ]; \
              then yum install -y VirtualBox-5.2 ; \
              else yum install -y VirtualBox-5.2-${VIRTUALBOX_VERSION} ; \
            fi && \
            yum clean all && rm -rf /var/cache/yum/*'

        // Install packer
        sh 'curl -L -o packer_${PACKER_VERSION}_linux_amd64.zip https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && \
            curl -L -o packer_${PACKER_VERSION}_SHA256SUMS https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS && \
            sed -i "/packer_${PACKER_VERSION}_linux_amd64.zip/!d" packer_${PACKER_VERSION}_SHA256SUMS && \
            sha256sum -c packer_${PACKER_VERSION}_SHA256SUMS && \
            unzip packer_${PACKER_VERSION}_linux_amd64.zip -d /bin && \
            rm -f packer_${PACKER_VERSION}_linux_amd64.zip'

        // Image build
        sh 'PACKER_LOG=1 /bin/packer build \
              -force \
              -debug \
              -var-file=centos7-desktop.json \
              -var "azure=true" \
              centos.json'
      }
    }

  }
}
