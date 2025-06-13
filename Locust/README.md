## Ejecución de pruebas con Locust

En la primera fase se realizaron pruebas de carga y estrés sobre los endpoints principales del sistema utilizando Locust. A continuación se muestran los resultados obtenidos:

### Resultados de la prueba

| Método | Endpoint                                      | # Req. | # Fails (%) | Prom. (ms) | Mín. (ms) | Máx. (ms) | Mediana (ms) | Req/s | Fails/s |
|--------|-----------------------------------------------|--------|-------------|------------|-----------|-----------|--------------|-------|---------|
| GET    | /app/api/address                             | 2845   | 0 (0.00%)   | 364        | 7         | 9393      | 59           | 7.64  | 0.00    |
| POST   | /app/api/authenticate                        | 1999   | 1491 (74.59%)| 23917      | 54        | 33031     | 30000        | 5.37  | 4.00    |
| GET    | /app/api/categories                          | 2802   | 0 (0.00%)   | 330        | 8         | 8804      | 60           | 7.52  | 0.00    |
| GET    | /app/api/credentials                         | 2849   | 0 (0.00%)   | 355        | 8         | 9693      | 57           | 7.65  | 0.00    |
| GET    | /app/api/favourites                          | 2855   | 0 (0.00%)   | 583        | 19        | 10063     | 140          | 7.66  | 0.00    |
| GET    | /app/api/orders                              | 2810   | 0 (0.00%)   | 329        | 8         | 8838      | 59           | 7.54  | 0.00    |
| GET    | /app/api/payments                            | 2843   | 0 (0.00%)   | 440        | 14        | 8979      | 99           | 7.63  | 0.00    |
| GET    | /app/api/products                            | 2736   | 0 (0.00%)   | 316        | 8         | 9373      | 58           | 7.34  | 0.00    |
| GET    | /app/api/shippings?orderId=1&productId=1     | 2867   | 0 (0.00%)   | 507        | 21        | 9009      | 150          | 7.70  | 0.00    |
| GET    | /app/api/users                               | 2871   | 0 (0.00%)   | 346        | 7         | 8747      | 61           | 7.71  | 0.00    |

**Explicación de resultados:**

- La mayoría de los endpoints GET respondieron correctamente, con tiempos de respuesta promedio bajos y sin fallos.
- El endpoint `POST /app/api/authenticate` presentó una alta tasa de fallos (74.59%) y tiempos de respuesta elevados, lo que indica un posible cuello de botella o problema de capacidad en la autenticación bajo carga.
- El resto de los endpoints mantuvieron un desempeño estable, con tiempos de respuesta aceptables y sin errores.
- Estos resultados sugieren que el sistema soporta adecuadamente la carga en la mayoría de los servicios, pero requiere optimización en el proceso de autenticación antes de avanzar a fases de prueba más intensivas.

