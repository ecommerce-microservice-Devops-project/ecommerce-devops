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
                    sh "helm lint ./ecommerce"

                    sh "helm upgrade --install ecommerce ./ecommerce -n ${K8S_NAMESPACE} -f ./ecommerce/values-${BRANCH_NAME}.yaml"
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
                    kubectl delete job ingress-nginx-admission-create -n ingress-nginx --ignore-not-found
                    kubectl delete job ingress-nginx-admission-patch -n ingress-nginx --ignore-not-found
                    kubectl get pods -n ingress-nginx || kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
                """
                // Aplica el recurso ingress correspondiente a la rama
                dir('helm/ecommerce/ingress') {
                    sh "kubectl apply -f api-gateway-ingress-${BRANCH_NAME}.yaml"
                }
            }
        }

        stage('Install ArgoCD') {
            steps {
                sh """
                    kubectl get ns argocd || kubectl create ns argocd
                    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
                    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/master/manifests/install.yaml
                """
            }
        }
        stage('Wait for Deployment') {
            steps {
                script {
                    echo "Esperando a que el despliegue se complete para la rama: ${BRANCH_NAME}"
                    def deployments = sh(script: "kubectl get deploy -n ${K8S_NAMESPACE} -o jsonpath='{.items[*].metadata.name}'", returnStdout: true).trim().split(" ")
                    for (d in deployments) {
                        sh "kubectl rollout status deployment/${d} -n ${K8S_NAMESPACE} --timeout=300s"
                    }
                }
            }
        }
        stage('Post-Deployment Verification') {
            steps {
                script {
                    echo "Verificando el despliegue para la rama: ${BRANCH_NAME}"
                    sh "kubectl get pods -n ${K8S_NAMESPACE}"
                    sh "kubectl get svc -n ${K8S_NAMESPACE}"
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