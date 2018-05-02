#!/usr/bin/groovy

// load pipeline functions
// Requires pipeline-github-lib plugin to load library from github

@Library('github.com/sylus/jenkins-pipeline@dev')

def pipeline = new io.estrado.Pipeline()

// UUID
def label = "packer-linux-${UUID.randomUUID().toString()}"

// Pod and Container template configuration
// https://github.com/jenkinsci/kubernetes-plugin#pod-and-container-template-configuration
podTemplate(
  label: label,
  envVars: [
    envVar(key: 'PACKER_VERSION', value: '1.2.0')
  ],
  nodeSelector: 'ci=vbox',
  serviceAccount: 'jenkins-jenkins',
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
                      ttyEnabled: true,
                      privileged: true),
    containerTemplate(name: 'vbox',
                      image: 'govcloud/docker-ubuntu:vbox',
                      command: 'cat',
                      ttyEnabled: true,
                      privileged: true),
    containerTemplate(name: 'azure-cli',
                      image: 'microsoft/azure-cli:2.0.31',
                      command: 'cat',
                      ttyEnabled: true),
  ],
  volumes:[
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
    hostPathVolume(mountPath: '/dev/vboxdrv', hostPath: '/dev/vboxdrv')
  ]) {

  node (label) {

    stage('Create immutable image') {

      // Update the gitlab status to pending
      // https://jenkins.io/doc/pipeline/steps/gitlab-plugin
      updateGitlabCommitStatus name: 'build', state: 'pending'

      // Checkout code from source control where scm instructs the checkout step
      // to clone the specific revision which triggered pipeline.
      checkout scm

      // Update the gitlab status to running
      updateGitlabCommitStatus name: 'build', state: 'running'


      // Variable assignment
      // https://jenkins.io/doc/book/pipeline/jenkinsfile/#string-interpolation
      def pwd = pwd()
      def inputFile = readFile('Jenkinsfile.json')
      def config = new groovy.json.JsonSlurperClassic().parseText(inputFile)
      println "pipeline config ==> ${config}"

      // Continue only if pipeline enabled
      if (!config.pipeline.enabled) {
          println "pipeline disabled"
          return
      }

      // Set additional git envvars
      pipeline.gitEnvVars()

      // If pipeline debugging enabled
      if (config.pipeline.debug) {
        println "DEBUG ENABLED"
        sh "env | sort"
      }

      // Allows various kinds of credentials (secrets) to be used in idiosyncratic ways.
      // https://jenkins.io/doc/pipeline/steps/credentials-binding/
      withCredentials([
          azureServicePrincipal(credentialsId: 'sp-jenkins-acr',
                          subscriptionIdVariable: 'SUBSCRIPTION_ID',
                          clientIdVariable: 'CLIENT_ID',
                          clientSecretVariable: 'CLIENT_SECRET',
                          tenantIdVariable: 'TENANT_ID'),
          usernamePassword(credentialsId: 'asb-user-devtestlab',
                          usernameVariable: 'ASB_USER',
                          passwordVariable: 'ASB_PASS')
      ]) {

      // Send a slack notification
      // https://jenkins.io/doc/pipeline/steps/slack
      slackSend (color: '#00FF00', message: "STARTED: Generation of immutable image '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")

      // Container for Azure CLI
      container('vbox') {

        // Packer provisioning from ISO
        sh 'packer build \
              -force \
              -var-file=centos7-desktop.json \
              -var "azure=true" \
              centos.json'
      }

      // Conversion from VMDK -> VHD
      sh 'export AZURE=true && \
          ./scripts/azure-vhd.sh _output/output-centos7-desktop-virtualbox-iso/centos7-desktop-disk001.vmdk'

      // Container for Azure CLI
      container('azure-cli') {
          // Authenticate to azure using Jenkins service principal
          sh 'az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET -t $TENANT_ID'
          sh 'az account set -s $SUBSCRIPTION_ID'

          // Upload the generated VHD file.
          sh 'az storage blob upload --account-name ${ASB_USER} \
                --account-key ${ASB_PASS} \
                --container-name mastervhds \
                --type page \
                --file _output/output-centos7-desktop-virtualbox-iso/centos7-desktop-disk001.vmdk.vhd \
                --name centos7-desktop-${env.BUILD_ID}.vhd'
      }

      slackSend (color: '#00FF00', message: "FINISHED: Generation of immutable image '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")

      // Update the gitlab status to success
      updateGitlabCommitStatus name: 'build', state: 'success'
    }

  }
}
