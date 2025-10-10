resource "helm_release" "dapr" {
  name       = "dapr"
  repository = "https://dapr.github.io/helm-charts"
  chart      = "dapr"
  version    = "1.15.5"
  namespace  = var.namespace
}


resource "random_password" "redis" {
  length  = 32
  special = false
}

resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = "17.14.2"
  namespace  = var.namespace

  set {
    name  = "auth.password"
    value = random_password.redis.result
  }
  set {
    name  = "image.repository"
    value = "bitnamilegacy/redis"
  }
  set {
    name  = "global.security.allowInsecureImages"
    value = "true"
  }
}

# -- comment out the two resources below when initially creating the cluster, somehow this fails to plan on the first run
/*
resource "kubernetes_manifest" "dapr_state_config" {
  manifest = {
    "apiVersion" = "dapr.io/v1alpha1"
    "kind"       = "Component"
    "metadata" = {
      "name"    = "statestore"
      namespace = var.namespace
    }
    "spec" = {
      "type"    = "state.redis"
      "version" = "v1"

      "metadata" = [
        {
          "name"  = "redisHost"
          "value" = "redis-master:6379"
        },
        {
          "name"  = "redisPassword"
          "value" = random_password.redis.result
        }
      ]
    }
  }
}



resource "kubernetes_manifest" "dapr_pubsub_config" {
  manifest = {
    "apiVersion" = "dapr.io/v1alpha1"
    "kind"       = "Component"
    "metadata" = {
      "name"    = "meitrex"
      namespace = var.namespace
    }

    "spec" = {
      "type"    = "pubsub.redis"
      "version" = "v1"

      "metadata" = [
        {
          "name"  = "redisHost"
          "value" = "redis-master:6379"
        },
        {
          "name"  = "redisPassword"
          "value" = random_password.redis.result
        }
      ]
    }
  }
}
*/
