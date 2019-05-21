#!groovy​

// The 'xchem' Fragalysis Stack Jenkinsfile.
//
// The Jenkins Job that uses this Jenkinsfile is expected to be parameterised,
// and must provide the following variables: -
//
// FE_GIT_PROJECT The name of the upstream FE project.
//                Typically 'xchem'.
//                The built docker image is only pushed to docker
//                if this variable's value is 'xchem'
// IMAGE_TAG      The tag to apply to the built stack image.
//                Typically 'latest'

pipeline {

  agent { label 'buildah-slave' }

  environment {
    // Local registry details (for FROM image)
    REGISTRY_USER = 'jenkins'
    REGISTRY = 'docker-registry.default.svc:5000'
    // Destination image (pushed to docker hub)
    IMAGE = 'xchem/fragalysis-stack'

    // Docker hub credentials
    DOCKER_USER = credentials('abcDockerUser')
    DOCKER_PASSWORD = credentials('abcDockerPassword')

    // Slack channel for all notifications
    SLACK_BUILD_CHANNEL = 'dls-builds'
    // Slack channel to be used for errors/failures
    SLACK_ALERT_CHANNEL = 'dls-alerts'
  }

  stages {

    stage('Build Image') {
      steps {
        slackSend channel: "#${SLACK_BUILD_CHANNEL}",
                  message: "${JOB_NAME} build ${BUILD_NUMBER} - starting..."
        script {
          TOKEN = sh(script: 'oc whoami -t', returnStdout: true).trim()
        }
        sh "buildah bud --tls-verify=false --creds=${REGISTRY_USER}:${TOKEN} --format docker --build-arg FE_GIT_PROJECT=${FE_GIT_PROJECT} -f Dockerfile-cicd -t ${IMAGE}:${IMAGE_TAG} ."
      }
    }

    stage('Push Image') {
      when {
        expression { FE_GIT_PROJECT == 'xchem' }
      }
      steps {
        sh "podman login --username ${DOCKER_USER} --password ${DOCKER_PASSWORD} docker.io"
        sh "buildah push ${IMAGE} docker://docker.io/${IMAGE}:${IMAGE_TAG}"
        sh "podman logout docker.io"
      }
    }

  }

  // Post-job actions.
  // See https://jenkins.io/doc/book/pipeline/syntax/#post
  post {

    success {
      slackSend channel: "#${SLACK_BUILD_CHANNEL}",
                color: 'good',
                message: "${JOB_NAME} build ${BUILD_NUMBER} - complete"
    }

    failure {
      slackSend channel: "#${SLACK_BUILD_CHANNEL}",
                color: 'danger',
                message: "${JOB_NAME} build ${env.BUILD_NUMBER} - failed (${BUILD_URL})"
      slackSend channel: "#${SLACK_ALERT_CHANNEL}",
                color: 'danger',
                message: "${JOB_NAME} build ${BUILD_NUMBER} - failed (${BUILD_URL})"
    }

    fixed {
      slackSend channel: "#${env.SLACK_ALERT_CHANNEL}",
                color: 'good',
                message: "${JOB_NAME} build - fixed"
    }

  }

}
