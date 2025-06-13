resource "helm_release" "keycloak" {
  name       = "keycloak"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "keycloak"
  namespace  = var.namespace

  set {
    name  = "auth.adminUser"
    value = "admin"
  }

  set {
    name  = "auth.adminPassword"
    value = var.keycloak_admin_pw
  }
  set {
    name  = "production"
    value = "true"
  }
  set {
    name  = "proxy"
    value = "edge"
  }
  set {
    name  = "httpRelativePath"
    value = "/keycloak/"
  }
  set {
    name  = "image.pullPolicy"
    value = "Always"
  }
  set {
    name  = "image.registry"
    value = "ghcr.io"
  }
  set {
    name  = "image.repository"
    value = "it-rex-platform/keycloak"
  }
  set {
    name  = "image.tag"
    value = "latest"
  }
}
