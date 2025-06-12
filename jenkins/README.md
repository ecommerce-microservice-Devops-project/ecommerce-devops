# Guía de Despliegue de Jenkins

Esta guía explica cómo construir, desplegar y acceder a Jenkins en un entorno de Kubernetes.

## 1. Construir y Publicar la Imagen Docker del Agente Jenkins

```sh
docker build -t sebas3004tian/jenkins-agent-k8s:latest -f Dockerfile.jenkins-agent .
docker push sebas3004tian/jenkins-agent-k8s:latest
```

## 2. Crear el Namespace para Jenkins

```sh
kubectl create namespace jenkins-namespace
```

## 3. Aplicar los Manifiestos de Kubernetes

```sh
kubectl apply -f jenkins-storage.yaml
kubectl apply -f jenkins-sa-rbac.yaml
kubectl apply -f jenkins-deployment.yaml
```

## 4. Verificar el Pod de Jenkins

```sh
kubectl get pods -n jenkins-namespace -l app=jenkins-server
```

## 5. Obtener la Contraseña Inicial del Administrador de Jenkins

Reemplaza `<jenkins-pod-name>` por el nombre real de tu pod:

```sh
kubectl exec -n jenkins-namespace <jenkins-pod-name> -- cat /var/jenkins_home/secrets/initialAdminPassword
```

Ejemplo de salida:
```
c88420bb80824902bc31d0bcf0e9d6ac
```

## 6. Exponer el Servicio de Jenkins

```sh
kubectl apply -f jenkins-service.yaml
```

## 7. Redireccionar el Puerto del Servicio de Jenkins

```sh
kubectl port-forward -n jenkins-namespace svc/jenkins-service 9090:8080
```

Ahora Jenkins estará accesible en [http://localhost:9090](http://localhost:9090).

## 8. Credenciales por Defecto

- **Usuario:** Admin
- **Contraseña:** (Utiliza el valor obtenido en el paso 5)
