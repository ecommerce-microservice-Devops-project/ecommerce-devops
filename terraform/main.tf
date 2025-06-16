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
resource "kubernetes_namespace" "qa" {
  metadata {
    name = "ecommerce-stage"
  }
}
resource "kubernetes_namespace" "prod" {
  metadata {
    name = "ecommerce-master"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "null_resource" "monitoring_stack" {
  depends_on = [kubernetes_namespace.monitoring]

  provisioner "local-exec" {
    command = "helm upgrade --install monitoring-stack ${path.module}/../helm/monitoring/kube-prometheus-stack -n monitoring"
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      helm uninstall monitoring-stack -n monitoring || true
    EOT
  }

  triggers = {
    chart_hash = filemd5("${path.module}/../helm/monitoring/kube-prometheus-stack/Chart.yaml")
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