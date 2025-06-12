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
                    sh "helm upgrade --install ecommerce ./ecommerce -n ecommerce-develop -f ./ecommerce/values-${BRANCH_NAME}.yaml"
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
                    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
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

        stage('Create ArgoCD Applications') {
            steps {
                script {
                    def services = [
                        "api-gateway",
                        "cloud-config",
                        "favourite-service",
                        "order-service",
                        "payment-service",
                        "product-service",
                        "proxy-client",
                        "service-discovery",
                        "shipping-service",
                        "user-service"
                    ]

                    services.each { service ->
                        def appFile = "${service}-app.yaml"
                        def image = "${DOCKERHUB_USER}/${service}"
                        def appYaml = """
                        apiVersion: argoproj.io/v1alpha1
                        kind: Application
                        metadata:
                        name: ${service}-app
                        namespace: argocd
                        annotations:
                            argocd-image-updater.argoproj.io/image-list: ${image}
                            argocd-image-updater.argoproj.io/${DOCKERHUB_USER}_${service}.update-strategy: latest
                            argocd-image-updater.argoproj.io/${DOCKERHUB_USER}_${service}.allow-tags: ^${BRANCH_NAME}-[0-9]+$
                        spec:
                        project: default
                        source:
                            repoURL: ${REPO_URL}
                            targetRevision: ${BRANCH_NAME}
                            path: helm/ecommerce
                            helm:
                            valueFiles:
                                - values.yaml
                        destination:
                            server: https://kubernetes.default.svc
                            namespace: ${K8S_NAMESPACE}
                        syncPolicy:
                            automated:
                            prune: true
                            selfHeal: true
                        """

                        writeFile file: appFile, text: appYaml
                        sh "kubectl apply -f ${appFile}"
                    }
                }
            }
        }

        stage('Update Image Tag in Helm values.yaml') {
            steps {
                sh """
                    sed -i 's/tag: .*/tag: ${IMAGE_TAG}/' helm/ecommerce/values.yaml
                    git config user.name "jenkins"
                    git config user.email "jenkins@ci.local"
                    git commit -am "Update image tag to ${IMAGE_TAG}"
                    git push origin ${BRANCH_NAME}
                """
            }
        }
        stage('Trigger ArgoCD Sync') {
            steps {
                script {
                    echo "Sincronizando ArgoCD para rama: ${BRANCH_NAME}"
                }
                sh "argocd app sync ecommerce-app --auth-token $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode)"
            }
        }
        stage('Wait for Deployment') {
            steps {
                script {
                    echo "Esperando a que el despliegue se complete para la rama: ${BRANCH_NAME}"
                    sh "kubectl rollout status deployment/user-service -n ${K8S_NAMESPACE} --timeout=600s"
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