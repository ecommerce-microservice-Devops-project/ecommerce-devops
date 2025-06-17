#!/bin/bash

# ⚙️ Variables
NAMESPACE="ecommerce-stage"
SECRET_NAME="my-tls-secret"
DOMAIN="local.test"
INGRESS_NAME="api-gateway-ingress"
SERVICE_NAME="api-gateway"
SERVICE_PORT="8080"

# Archivos temporales
CERT_FILE="tls.crt"
KEY_FILE="tls.key"
INGRESS_FILE="tls-ingress.yaml"

# 1. Crear certificado autofirmado
echo "Generando certificado autofirmado para $DOMAIN..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -out $CERT_FILE -keyout $KEY_FILE \
  -subj "/CN=$DOMAIN/O=$DOMAIN"

# 2. Crear namespace si no existe
echo "Asegurando que el namespace '$NAMESPACE' existe..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 3. Crear o reemplazar el Secret TLS
echo "Creando Secret TLS '$SECRET_NAME' en el namespace '$NAMESPACE'..."
kubectl delete secret $SECRET_NAME -n $NAMESPACE --ignore-not-found
kubectl create secret tls $SECRET_NAME --cert=$CERT_FILE --key=$KEY_FILE -n $NAMESPACE

# 4. Crear archivo Ingress con TLS
echo "Generando archivo Ingress con TLS..."
cat <<EOF > $INGRESS_FILE
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $INGRESS_NAME
  namespace: $NAMESPACE
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - $DOMAIN
      secretName: $SECRET_NAME
  rules:
    - host: $DOMAIN
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: $SERVICE_NAME
                port:
                  number: $SERVICE_PORT
EOF

# 5. Aplicar el Ingress
echo "Aplicando Ingress..."
kubectl apply -f $INGRESS_FILE

# 6. Agregar al /etc/hosts si no está presente
if ! grep -q "$DOMAIN" /etc/hosts; then
  echo "Agregando '$DOMAIN' a /etc/hosts..."
  echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts
else
  echo "El dominio '$DOMAIN' ya está en /etc/hosts."
fi

# 7. Probar acceso con curl
echo -e "\nPrueba de conexión:"
curl -k https://$DOMAIN/

# 8. Limpiar archivos temporales (opcional)
# rm -f $CERT_FILE $KEY_FILE $INGRESS_FILE

echo -e "\nListo. Puedes acceder en: https://$DOMAIN/"
