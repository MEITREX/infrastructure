variable "keycloak_admin_pw" {
  sensitive = true
  type      = string
}
variable "namespace" {
  sensitive = false
  type = string
}
variable "github_client_id" {
  sensitive = true
  type = string
}
variable "github_client_secret" {
  sensitive = true
  type = string
  
}
