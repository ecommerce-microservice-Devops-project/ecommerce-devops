pipeline {
    agent any

    environment {
        DOCKERHUB_USER = "sebas3004tian"
        IMAGE_TAG = "${env.BRANCH_NAME}-2"
        BRANCH_NAME = "${env.BRANCH_NAME}"
        REPO_URL = "https://github.com/ecommerce-microservice-Devops-project/helm-charts-microservices.git"
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
                    sh 'helm upgrade --install ecommerce ./ecommerce -n ecommerce-develop -f ./ecommerce/values.yaml'
                }
            }
        }

        stage('Deploy Ingress') {
            steps {
                script {
                    echo "Desplegando Ingress para rama: ${BRANCH_NAME}"
                }
                // Instala el Ingress Controller
                sh """
                    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
                """
                // Aplica el recurso ingress correspondiente a la rama
                dir('helm/ecommerce/ingress') {
                    sh "kubectl apply -f api-gateway-ingress-${BRANCH_NAME}.yaml"
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