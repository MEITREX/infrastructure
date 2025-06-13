resource "helm_release" "keycloak" {
  name       = "keycloak"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "keycloak"
  version    = "24.7.4"
  namespace  = var.namespace

  set {
    name  = "global.security.allowInsecureImages"
    value = "true"
  }

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
    value = "meitrex/keycloak"
  }

  set {
    name  = "image.tag"
    value = "latest"
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.hostname"
    value = "dev.meitrex.de"
  }

  set {
    name  = "ingress.path"
    value = "/keycloak"
  }

  set {
    name  = "adminIngress.enabled"
    value = "true"
  }

  set {
    name  = "adminIngress.hostname"
    value = "dev.meitrex.de"
  }

  set {
    name  = "adminIngress.path"
    value = "/keycloak"
  }
  
}
