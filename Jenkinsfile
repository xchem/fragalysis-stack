#!groovy​

// The 'xchem' Fragalysis Stack Jenkinsfile.

pipeline {

  agent { label 'buildah-slave' }

  environment {
    // Local registry details (for FROM image)
    REGISTRY_USER = 'jenkins'
    REGISTRY = 'docker-registry.default:5000'
    // Destination image (pushed to docker hub)
    IMAGE = 'xchem/fragalysis-stack:latest'
    DOCKER_USER = 'alanbchristie'
    DOCKER_PASSWORD = credentials('abcDockerPassword')
  }

  stages {

    stage('Build Image') {
      steps {
        script {
          TOKEN = sh(script: 'oc whoami -t', returnStdout: true).trim()
        }
        sh "buildah bud --tls-verify=false --creds=${env.REGISTRY_USER}:${TOKEN} --format docker -f Dockerfile-cicd -t ${env.IMAGE} ."
      }
    }

    stage('Push Image') {
      steps {
        sh "podman login --username ${env.DOCKER_USER} --password ${env.DOCKER_PASSWORD} docker.io"
        sh "buildah push ${env.IMAGE} docker://docker.io/${env.IMAGE}"
        sh "podman logout docker.io"
      }
    }

  }

}
