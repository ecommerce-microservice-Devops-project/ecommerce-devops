from locust import HttpUser, TaskSet, task, between
import urllib3

# Desactivar advertencias por certificados autofirmados
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class UserBehavior(TaskSet):
    def on_start(self):
        """ Autenticación inicial para obtener el token """
        login_payload = {
            "username": "admin",
            "password": "password"
        }

        response = self.client.post(
            "/app/api/authenticate", json=login_payload, verify=False
        )

        print("Login response status:", response.status_code)
        print("Login response text:", response.text)

        self.headers = {}

        if response.status_code == 200:
            try:
                token = response.json().get("jwtToken")
                if token:
                    self.headers = {"Authorization": f"Bearer {token}"}
                else:
                    print("JWT token not found in login response.")
            except Exception as e:
                print("Failed to parse login response JSON:", e)
        else:
            print("Login failed:", response.status_code)

    @task
    def get_categories(self):
        self.client.get("/app/api/categories", headers=self.headers, verify=False)

    @task
    def get_products(self):
        self.client.get("/app/api/products", headers=self.headers, verify=False)

    @task
    def get_payments(self):
        self.client.get("/app/api/payments", headers=self.headers, verify=False)

    @task
    def get_address(self):
        self.client.get("/app/api/address", headers=self.headers, verify=False)

    @task
    def get_orders(self):
        self.client.get("/app/api/orders", headers=self.headers, verify=False)

    @task
    def get_shippings(self):
        self.client.get("/app/api/shippings?orderId=1&productId=1", headers=self.headers, verify=False)

    @task
    def get_favourites(self):
        self.client.get("/app/api/favourites", headers=self.headers, verify=False)

    @task
    def get_users(self):
        self.client.get("/app/api/users", headers=self.headers, verify=False)

    @task
    def get_credentials(self):
        self.client.get("/app/api/credentials", headers=self.headers, verify=False)


class WebsiteUser(HttpUser):
    tasks = [UserBehavior]
    wait_time = between(1, 5)
    host = "https://local.test"
