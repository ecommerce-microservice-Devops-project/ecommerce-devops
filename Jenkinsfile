pipeline {
    agent any

    environment {
        DOCKERHUB_USER = "sebas3004tian"
        IMAGE_TAG = "${env.BRANCH_NAME}-2"
        BRANCH_NAME = "${env.BRANCH_NAME}"
        REPO_URL = "https://github.com/ecommerce-microservice-Devops-project/ecommerce-microservice-backend-app.git"
        K8S_NAMESPACE = "ecommerce-${BRANCH_NAME}" 
    }


    stages {
        stage('Prepare Namespace') {
            steps {
                sh "kubectl get namespace ${K8S_NAMESPACE} || kubectl create namespace ${K8S_NAMESPACE}"
            }
        }

        stage('Checkout') {
            steps {
                git branch: "${BRANCH_NAME}", url: "${REPO_URL}"
            }
        }

        stage('Deploy Services') {
            steps {
                dir('helm') {
                    sh "helm upgrade --install ecommerce ecommerce -n ${K8S_NAMESPACE} -f ecommerce/values.yaml"
                }
            }
        }


    }

    post {
        failure {
            echo 'Pipeline falló, revisa los logs.'
        }
        always {
            echo "Pipeline ejecutado en el namespace: ${K8S_NAMESPACE}"
        }
    }
}