from locust import HttpUser, TaskSet, task, between
import json

class UserBehavior(TaskSet):
    def on_start(self):
        """ Autenticación inicial para obtener el token """
        login_payload = {
            "username": "admin",
            "password": "password"
        }
        response = self.client.post("/app/api/authenticate", json=login_payload)
        token = response.json()["jwtToken"]
        self.headers = {"Authorization": f"Bearer {token}"}

    @task
    def get_categories(self):
        self.client.get("/app/api/categories", headers=self.headers)

    @task
    def get_products(self):
        self.client.get("/app/api/products", headers=self.headers)

    @task
    def get_payments(self):
        self.client.get("/app/api/payments", headers=self.headers)

    @task
    def get_address(self):
        self.client.get("/app/api/address", headers=self.headers)

    @task
    def get_orders(self):
        self.client.get("/app/api/orders", headers=self.headers)

    @task
    def get_shippings(self):
        self.client.get("/app/api/shippings?orderId=1&productId=1", headers=self.headers)

    @task
    def get_favourites(self):
        self.client.get("/app/api/favourites", headers=self.headers)

    @task
    def get_users(self):
        self.client.get("/app/api/users", headers=self.headers)

    @task
    def get_credentials(self):
        self.client.get("/app/api/credentials", headers=self.headers)

class WebsiteUser(HttpUser):
    tasks = [UserBehavior]
    wait_time = between(1, 5)
    host = "http://localhost"
