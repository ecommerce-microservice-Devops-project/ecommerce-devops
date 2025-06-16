
# Guía de Despliegue con Minikube, Terraform, Jenkins y Herramientas de Observabilidad

Este documento guía paso a paso el proceso de levantar una infraestructura local con Minikube, Jenkins, ELK, Grafana, Prometheus y ArgoCD, usando Terraform y Helm.

---

## Requisitos previos

- Tener `Minikube`, `kubectl`, `Terraform`, `Helm`, y `Docker` instalados.
- Tener tu proyecto con Helm Charts y los manifiestos necesarios.

---

## 1. Iniciar Minikube

Ejecuta Minikube con recursos suficientes y el plugin de red Calico:

```bash
minikube start --memory=10240 --cpus=4 --cni=calico
minikube addons enable ingress
minikube addons enable metrics-server
```

---

## 2. Aplicar Terraform

Inicializamos y aplicamos la configuración de infraestructura declarada con Terraform:

```bash
terraform init
terraform apply
```

Esto creará:
- Namespaces: `jenkins-namespace`, `ecommerce-develop`, etc.
- Recursos como Jenkins, NetworkPolicies, etc.

---

## 3. Obtener contraseña de Jenkins

Luego de desplegar Jenkins, obtenemos la contraseña inicial para el usuario `admin`:

```bash
kubectl exec -n jenkins-namespace nombre-del-pod-jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

Ejemplo (si tu pod se llama `jenkins-5f8887b8b5-ds5dm`):

```bash
kubectl exec -n jenkins-namespace jenkins-5f8887b8b5-ds5dm -- cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## 4. Exponer servicios con `port-forward`

```bash
kubectl port-forward -n jenkins-namespace svc/jenkins-service 9090:8080
kubectl port-forward svc/monitoring-stack-grafana -n monitoring 3000:80
kubectl port-forward svc/monitoring-stack-kube-prom-prometheus -n monitoring 9091:9090
```

---

## 5. Acceder a Grafana

- URL: [http://localhost:3000](http://localhost:3000)
- Usuario: `admin`
- Contraseña: `prom-operator`

---

## 6. Configurar Jenkins

1. Accede a Jenkins en: [http://localhost:9090](http://localhost:9090)
2. Inicia sesión con la contraseña obtenida anteriormente.
3. Agrega un nuevo **Multibranch Pipeline** apuntando a tu repositorio.
4. Jenkins detectará las ramas y ejecutará los pipelines automáticamente.

---

## 7. Comando adicional al final del pipeline

Para permitir el despliegue correctamente, añade al final del pipeline:

```bash
kubectl delete networkpolicy -n ecommerce-develop --all
helm upgrade ecommerce . -n ecommerce-develop -f values-develop.yaml
```

---

## 8. Verificación de recursos en Kubernetes

### Ver labels de namespaces y pods

```bash
kubectl get ns --show-labels
kubectl get pods -n ecommerce-develop --show-labels
```

### Ver Horizontal Pod Autoscaler (HPA)

```bash
kubectl get hpa -n ecommerce-develop
```

### Ver Network Policies (NP)

```bash
kubectl get networkpolicy -n ecommerce-develop
```

---

## 9. Acceder a ELK (Kibana)

```bash
minikube service kibana -n logging-stack
```

---

## 10. Acceder a ArgoCD

```bash
kubectl port-forward svc/argocd-server -n argocd 8082:80
```

Luego accede a [http://localhost:8082](http://localhost:8082)

---

## Recomendaciones

- Usa `kubectl get all -A` para monitorear todos los recursos.
- Si algo falla, consulta los logs con:  
  ```bash
  kubectl logs nombre-del-pod -n namespace
  ```

---
