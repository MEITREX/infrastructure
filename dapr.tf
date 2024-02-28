resource "helm_release" "dapr" {
  name       = "dapr"
  repository = "https://dapr.github.io/helm-charts"
  chart      = "dapr"
  namespace  = kubernetes_namespace.gits.metadata[0].name
}


resource "random_password" "redis" {
  length  = 32
  special = false
}

resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  namespace  = kubernetes_namespace.gits.metadata[0].name

  set {
    name  = "auth.password"
    value = random_password.redis.result
  }
}

resource "kubectl_manifest" "dapr_state_config" {
  depends_on = [kubernetes_namespace.gits]
  yaml_body  = <<-EOF
  apiVersion:  "dapr.io/v1alpha1"
  kind: "Component"
  metadata:
    name: "statestore"
    namespace: ${kubernetes_namespace.gits.metadata[0].name}

  spec:
    type: "state.redis"
    version: "v1"

    metadata:
      - name: "redisHost"
        value: "redis-master:6379"
      - name: "redisPassword"
        value: ${random_password.redis.result}
  EOF
}

resource "kubectl_manifest" "dapr_pubsub_config" {
  depends_on = [kubernetes_namespace.gits]
  yaml_body  = <<-EOF
  apiVersion:  "dapr.io/v1alpha1"
  kind: "Component"
  metadata:
    name: "gits"
    namespace: ${kubernetes_namespace.gits.metadata[0].name}

  spec:
    type: "pubsub.redis"
    version: "v1"

    metadata:
      - name: "redisHost"
        value: "redis-master:6379"
      - name: "redisPassword"
        value: ${random_password.redis.result}
  EOF
}
