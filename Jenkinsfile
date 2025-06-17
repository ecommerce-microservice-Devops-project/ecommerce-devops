pipeline {
    agent any

    environment {
        DOCKERHUB_USER = "sebas3004tian"
        IMAGE_TAG = "${env.BRANCH_NAME}-2"
        BRANCH_NAME = "${env.BRANCH_NAME}"
        REPO_URL = "https://github.com/ecommerce-microservice-Devops-project/ecommerce-devops.git"
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
        stage('Actualizar tags') {
            steps {
                dir('helm') {
                    sh '''#!/bin/bash
                    SERVICES=(
                    "api-gateway"
                    "cloud-config"
                    "favourite-service"
                    "order-service"
                    "payment-service"
                    "product-service"
                    "proxy-client"
                    "service-discovery"
                    "shipping-service"
                    "user-service"
                    )

                    FILE="ecommerce/values-${BRANCH_NAME}.yaml"

                    for SERVICE in "${SERVICES[@]}"; do
                    IMAGE_REPO="sebas3004tian/${SERVICE}-ecommerce-boot"

                    TAG=$(curl -s "https://hub.docker.com/v2/repositories/${IMAGE_REPO}/tags?page_size=100" |
                        grep -o '"name":"[^"]*"' |
                        sed 's/"name":"//;s/"//' |
                        grep "^${BRANCH_NAME}-" |
                        sort -V |
                        tail -n 1)

                    echo "Último tag para $SERVICE: $TAG"

                    sed -i "/${SERVICE}:$/,/tag:/s/tag: .*/tag: ${TAG}/" "$FILE"
                    done
                    '''
                }
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

        stage('Quite Network Policies') {
            steps {
                sh "kubectl delete networkpolicy -n ${K8S_NAMESPACE} --all"
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
       stage('Setup ELK Stack') {
            steps {
                dir('ELK') {
                    script {
                        sh 'kubectl get namespace logging-stack || kubectl create namespace logging-stack'

                        echo 'Aplicando Elasticsearch...'
                        sh '''
                            kubectl apply -f elasticsearch/elasticsearch-statefulset.yaml -n logging-stack
                            kubectl apply -f elasticsearch/elasticsearch-service.yaml -n logging-stack
                        '''

                        echo 'Aplicando Kibana...'
                        sh '''
                            kubectl apply -f kibana/kibana-deployment.yaml -n logging-stack
                            kubectl apply -f kibana/kibana-service.yaml -n logging-stack
                        '''

                        echo 'Aplicando Filebeat...'
                        sh '''
                            kubectl apply -f filebeat/filebeat-configmap.yaml -n logging-stack
                            kubectl apply -f filebeat/filebeat-rbac.yaml -n logging-stack
                            kubectl apply -f filebeat/filebeat-daemonset.yaml -n logging-stack
                        '''
                        echo 'Añadiendo purpose para monitoreo...'
                        sh ''' 
                            kubectl label namespace monitoring purpose=observability
                            kubectl label namespace logging-stack purpose=observability
                        '''
                    }
                }
            }
        }

        stage('Añadir purpose para monitoreo') {
            steps {
                script {
                    echo 'Añadiendo purpose para monitoreo...'
                    sh ''' 
                        kubectl label namespace monitoring purpose=observability
                        kubectl label namespace logging-stack purpose=observability
                    '''
                }
            }
        }

        stage('Wait for Core Deployments') {
            steps {
                script {
                    echo "Esperando despliegue de servicios CORE"
                    def coreDeployments = ['cloud-config', 'zipkin', 'service-discovery']
                    for (d in coreDeployments) {
                        echo "Esperando despliegue de ${d}"
                        sh "kubectl rollout status deployment/${d} -n ${K8S_NAMESPACE} --timeout=900s"
                    }
                }
            }
        }

        stage('Wait for Other Deployments') {
            steps {
                script {
                    echo "Esperando despliegue del resto de microservicios"
                    // Obtener todos los deployments excepto los CORE
                    def allDeployments = sh(script: "kubectl get deploy -n ${K8S_NAMESPACE} -o jsonpath='{.items[*].metadata.name}'", returnStdout: true).trim().split(" ")
                    def coreDeployments = ['cloud-config', 'zipkin', 'service-discovery']
                    def otherDeployments = allDeployments.findAll { !coreDeployments.contains(it) }
                    
                    for (d in otherDeployments) {
                        echo "Esperando despliegue de ${d}"
                        sh "kubectl rollout status deployment/${d} -n ${K8S_NAMESPACE} --timeout=600s"
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
        stage('Enable Network Policies') {
            steps {
                dir('helm') {
                    sh "helm upgrade ecommerce ./ecommerce -n ${K8S_NAMESPACE} -f ./ecommerce/values-${BRANCH_NAME}.yaml"
                }
            }
        }
        
        stage('ZAP Security Scan') {
            steps {
                sh '''
                    docker run --rm -v $WORKSPACE:/zap/wrk/:rw -t ghcr.io/zaproxy/zaproxy:stable \
                    zap-full-scan.py -t http://api-gateway.${K8S_NAMESPACE}.svc.cluster.local:8080 \
                    -r zap-report.html || true
                '''
            }
        }

    }
    

    post {
        failure {
            echo 'Pipeline falló, revisa los logs.'
        }
        always {
            echo "Pipeline ejecutado en el namespace: ${K8S_NAMESPACE}"
            archiveArtifacts artifacts: 'zap-report.html', allowEmptyArchive: true
        }
    }
}