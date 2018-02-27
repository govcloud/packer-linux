#!/usr/bin/groovy

// load pipeline functions
// Requires pipeline-github-lib plugin to load library from github

@Library('github.com/sylus/jenkins-pipeline@dev')

def pipeline = new io.estrado.Pipeline()
def label = "packer-linux-${UUID.randomUUID().toString()}"

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
  ],
  volumes:[
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
    hostPathVolume(mountPath: '/dev/vboxdrv', hostPath: '/dev/vboxdrv')
  ]) {

  node (label) {
    stage('Create immutable image') {

      checkout scm

      def pwd = pwd()
      def inputFile = readFile('Jenkinsfile.json')
      def config = new groovy.json.JsonSlurperClassic().parseText(inputFile)
      println "pipeline config ==> ${config}"

      // continue only if pipeline enabled
      if (!config.pipeline.enabled) {
          println "pipeline disabled"
          return
      }

      // set additional git envvars for image tagging
      pipeline.gitEnvVars()

      // If pipeline debugging enabled
      if (config.pipeline.debug) {
        println "DEBUG ENABLED"
        sh "env | sort"
      }

      container('vbox') {

        // Image build
        sh 'packer build \
              -force \
              -var-file=centos7-desktop.json \
              -var "azure=true" \
              centos.json'
      }
    }

  }
}
