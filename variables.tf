variable "keycloak_admin_pw" {
  sensitive = true
  type      = string
  description = "Default admin password for Keycloak. Change this after initial setup."
}
variable "namespace" {
  sensitive = false
  type      = string
  description = "Kubernetes namespace for MEITREX deployment."
  default   = "meitrex"
}
variable "github_client_id" {
  sensitive = true
  type      = string
  description = "GitHub client ID for OAuth authentication."
}
variable "github_client_secret" {
  sensitive = true
  type      = string
  description = "GitHub client secret for OAuth authentication."

}
variable "ssh_key_path" {
  sensitive = true
  type      = string
  description = "Path to the SSH private key for accessing the SQA GPU Workstation via SSH."
  default = "~/.ssh/id_rsa"
}
