#!/bin/bash

set -e

DESTINATION_DIR="helm/monitoring/kube-prometheus-stack/templates"
SERVICES=(
  "api-gateway"
  "cloud-config"
  "proxy-client"
  "service-discovery"
  "product-service"
  "order-service"
  "payment-service"
  "shipping-service"
  "user-service"
  "favourite-service"
  "zipkin"
)
NAMESPACES=("ecommerce-dev" "ecommerce-stage" "ecommerce-prod")

echo "Creating ServiceMonitor templates in $DESTINATION_DIR ..."

mkdir -p "$DESTINATION_DIR"

for service in "${SERVICES[@]}"; do
  FILENAME="${DESTINATION_DIR}/${service}-monitor.yaml"
  APP_LABEL="$service"

  cat > "$FILENAME" <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ${service}-monitor
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: $APP_LABEL
  namespaceSelector:
    matchNames:
$(for ns in "${NAMESPACES[@]}"; do echo "    - $ns"; done)
  endpoints:
  - port: http
    path: /actuator/prometheus
    interval: 15s
EOF

  echo "Created: $FILENAME"
done

echo "All ServiceMonitors generated in $DESTINATION_DIR."
