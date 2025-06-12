variable "dockerhub_user" {
  type        = string
  description = "Usuario de Docker Hub"
  sensitive   = true
}

variable "dockerhub_pass" {
  type        = string
  description = "Contraseña de Docker Hub"
  sensitive   = true
}
