provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins-namespace"
  }
}

resource "kubernetes_namespace" "dev" {
  metadata {
    name = "ecommerce-develop"
  }
}

# Aplicar los archivos YAML de Jenkins usando kubectl
resource "null_resource" "jenkins_deployment" {
  depends_on = [kubernetes_namespace.jenkins]
  
  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f ${path.module}/../jenkins/jenkins-storage.yaml
      kubectl apply -f ${path.module}/../jenkins/jenkins-sa-rbac.yaml
      kubectl apply -f ${path.module}/../jenkins/jenkins-deployment.yaml
      kubectl apply -f ${path.module}/../jenkins/jenkins-service.yaml
    EOT
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl delete -f ${path.module}/../jenkins/jenkins-service.yaml --ignore-not-found=true
      kubectl delete -f ${path.module}/../jenkins/jenkins-deployment.yaml --ignore-not-found=true
      kubectl delete -f ${path.module}/../jenkins/jenkins-sa-rbac.yaml --ignore-not-found=true
      kubectl delete -f ${path.module}/../jenkins/jenkins-storage.yaml --ignore-not-found=true
    EOT
  }
  
  # Trigger para re-ejecutar si los archivos cambian
  triggers = {
    storage_hash    = filemd5("${path.module}/../jenkins/jenkins-storage.yaml")
    sa_rbac_hash    = filemd5("${path.module}/../jenkins/jenkins-sa-rbac.yaml")
    deployment_hash = filemd5("${path.module}/../jenkins/jenkins-deployment.yaml")
    service_hash    = filemd5("${path.module}/../jenkins/jenkins-service.yaml")
  }
}