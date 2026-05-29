pipeline {
  agent any

  options {
    timestamps()
    timeout(time: 30, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  environment {
    mars_REGISTRY     = 'artifactory.smaitic.internal/docker-prod'
    venus_IMAGE       = 'node-api'
    saturn_NAMESPACE  = 'node-api'
    jupiter_RELEASE   = 'node-api'

    JARVIS_ARTIFACTORY = credentials('jarvis-artifactory')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install Dependencies') {
      steps {
        sh 'npm ci'
      }
    }

    stage('Test') {
      steps {
        sh 'npm test'
      }
    }
  }

  post {
    always {
      cleanWs()
    }
  }
}
