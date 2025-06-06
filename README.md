# Proyecto: Despliegue de Microservicios en Kubernetes

A continuación se explican los pasos para desplegar y gestionar los microservicios del proyecto **ecommerce** usando Minikube, Helm y Kubernetes.

## 1. Eliminar el namespace anterior (opcional)

Elimina el namespace `ecommerce-dev` si existe, para empezar desde cero:

```bash
kubectl delete namespace ecommerce-dev
```

## 2. Iniciar Minikube

Inicia Minikube con recursos suficientes y habilita el complemento de ingress:

```bash
minikube start --memory=10240 --cpus=4 --cni=calico
minikube addons enable ingress
```

## 3. Crear un nuevo namespace

Crea el namespace donde se desplegarán los recursos:

```bash
kubectl create namespace ecommerce-dev
```

## 4. Instalar el chart de Helm

Despliega la aplicación usando Helm en el namespace creado:

```bash
helm install ecommerce . -n ecommerce-dev -f values.yaml
```

## 5. Verificar el estado de los recursos

Consulta el estado de los pods y servicios:

```bash
kubectl get pods -n ecommerce-dev
kubectl get svc -n ecommerce-dev
```

Para ver las imágenes usadas por los deployments:

```bash
kubectl get deployment -n ecommerce-dev -o=jsonpath='{range .items[*]}{.metadata.name}{" => "}{.spec.template.spec.containers[*].image}{"\n"}{end}'
```

## 6. Redirección de puertos (Port-forward)

Permite el acceso local a los servicios principales:

```bash
kubectl port-forward svc/zipkin -n ecommerce-dev 9411:9411
kubectl port-forward svc/api-gateway -n ecommerce-dev 8081:8080
kubectl port-forward svc/service-discovery -n ecommerce-dev 8761:8761
```

## 7. Desplegar y verificar Ingress NGINX

Despliega el controlador de ingress y verifica su estado:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

## 8. Configurar el Ingress para el API Gateway

Aplica la configuración de ingress para el API Gateway y verifica su estado:

```bash
kubectl apply -f api-gateway-ingress.yaml
kubectl describe ingress api-gateway-ingress -n ecommerce-dev
kubectl get ingress -n ecommerce-dev -o wide
```

---

Estos pasos permiten desplegar y exponer los microservicios del proyecto **ecommerce** en un entorno local de Kubernetes usando Minikube y Helm.
