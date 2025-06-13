resource "helm_release" "keel" {
  name       = "keel"
  repository = "https://charts.keel.sh"
  namespace  = var.namespace
  chart      = "keel"
  version   = "1.0.3"

  set {
    name  = "helmProvider.enabled"
    value = "false"
  }
}
