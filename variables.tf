variable "keycloak_admin_pw" {
  sensitive = true
  type      = string
}
variable "namespace" {
  sensitive = false
  type = string
}
