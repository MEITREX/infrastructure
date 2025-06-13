resource "helm_release" "keel" {
  name       = "keel"
  repository = "https://charts.keel.sh"
  namespace  = var.namespace
  chart      = "keel"

  set {
    name  = "helmProvider.enabled"
    value = "false"
  }
}
