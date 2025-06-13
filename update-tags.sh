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

FILE="values-${BRANCH_NAME}.yaml"

for SERVICE in "${SERVICES[@]}"; do
  IMAGE_REPO="sebas3004tian/${SERVICE}-ecommerce-boot"

  #echo "Consultando tags para: $IMAGE_REPO"

  # Obtener todos los tags que coincidan con el branch
  TAG=$(curl -s "https://hub.docker.com/v2/repositories/${IMAGE_REPO}/tags?page_size=100" |
    grep -o '"name":"[^"]*"' |
    sed 's/"name":"//;s/"//' |
    grep "^${BRANCH_NAME}-" |
    sort -V |
    tail -n 1)

  echo "Último tag para $SERVICE: $TAG"

  # Reemplazar el tag correspondiente en el archivo YAML
  # Asume que la línea `tag:` está presente en la forma `.image.tag`
  #sed -i "/${SERVICE}:$/,/tag:/s/tag: .*/tag: ${TAG}/" "$FILE"
done
