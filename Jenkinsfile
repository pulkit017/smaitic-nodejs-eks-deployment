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
    mercury_CHART     = 'helm'
    neptune_CLUSTER   = 'prod-eks'
    earth_AWS_REGION  = 'ap-south-1'
    pluto_TAG         = "${env.GIT_COMMIT?.take(7)}-${env.BUILD_NUMBER}"

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

    stage('Docker Build') {
      steps {
        sh """
          docker build -t ${mars_REGISTRY}/${venus_IMAGE}:${pluto_TAG} .
        """
      }
    }

    stage('Trivy Scan') {
      steps {
        sh """
          trivy image \
            --exit-code 1 \
            --severity HIGH,CRITICAL \
            --ignore-unfixed \
            --no-progress \
            ${mars_REGISTRY}/${venus_IMAGE}:${pluto_TAG}
        """
      }
    }

    stage('Push Image') {
      steps {
        sh """
          echo "\$JARVIS_ARTIFACTORY_PSW" | docker login ${mars_REGISTRY} \
            -u "\$JARVIS_ARTIFACTORY_USR" --password-stdin
          docker push ${mars_REGISTRY}/${venus_IMAGE}:${pluto_TAG}
        """
      }
    }

    stage('Helm Lint') {
      steps {
        sh "helm lint ${mercury_CHART}"
      }
    }

    stage('Helm Deploy') {
      when { branch 'main' }
      steps {
        sh """
          aws eks update-kubeconfig --name ${neptune_CLUSTER} --region ${earth_AWS_REGION}

          helm upgrade --install ${jupiter_RELEASE} ${mercury_CHART} \
            --namespace ${saturn_NAMESPACE} --create-namespace \
            --set image.repository=${mars_REGISTRY}/${venus_IMAGE} \
            --set image.tag=${pluto_TAG} \
            --atomic --wait --timeout 5m
        """
      }
    }
  }

  post {
    always {
      sh 'docker logout ${mars_REGISTRY} || true'
      cleanWs()
    }
  }
}
