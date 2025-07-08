resource "kubernetes_deployment" "gits_graphql_gateway" {
  depends_on = [helm_release.dapr, helm_release.keel]
  metadata {
    name = "gits-gateway"
    labels = {
      app = "gits-gateway"
    }
    namespace = var.namespace
    annotations = {
      "keel.sh/policy"    = "force"
      "keel.sh/match-tag" = "true"
      "keel.sh/trigger"   = "poll"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "gits-gateway"
      }
    }

    template {
      metadata {
        labels = {
          app = "gits-gateway"
        }

        annotations = {
          "dapr.io/enabled"  = true
          "dapr.io/enable-metrics" = true
          "dapr.io/app-id"   = "gateway"
          "dapr.io/app-port" = 8080
          "dapr.io/sidecar-cpu-request" = "100m"
          "dapr.io/sidecar-cpu-limit"   = "200m"
          "dapr.io/sidecar-memory-request" = "100Mi"
          "dapr.io/sidecar-memory-limit"   = "200Mi"
          "dapr.io/env" = "GOMEMLIMIT=180MiB"
        }

      }

      spec {
        container {
          image             = "ghcr.io/meitrex/graphql_gateway:latest"
          image_pull_policy = "Always"

          name = "gits-gateway"

          resources {
            requests = {
              cpu    = "100m"
              memory = "500Mi"
            }
          }

          env {
            name  = "GATEWAY_HOSTNAME"
            value = "0.0.0.0"
          }
          env {
            name  = "GATEWAY_PORT"
            value = "8080"
          }
          env {
            name  = "COURSE_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/course-service/method/graphql"
          }
          env {
            name  = "MEDIA_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/media-service/method/graphql"
          }
          env {
            name  = "CONTENT_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/content-service/method/graphql"
          }
          env {
            name  = "USER_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/user-service/method/graphql"
          }
          env {
            name  = "FLASHCARD_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/flashcard-service/method/graphql"
          }
          env {
            name  = "REWARD_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/reward-service/method/graphql"
          }
          env {
            name  = "QUIZ_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/quiz-service/method/graphql"
          }
          env {
            name  = "SKILLLEVEL_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/skilllevel-service/method/graphql"
          }
          env {
            name  = "DOCPROCAI_SERVICE_URL"
            value = "http://129.69.217.248:9901/graphql/"
          }
          env {
            name  = "GAMIFICATION_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/gamification-service/method/graphql"
          }
          env {
            name  = "JWKS_URL"
            value = "https:/dev.meitrex.de/keycloak/realms/GITS/protocol/openid-connect/certs"
          }


          liveness_probe {
            http_get {
              path = "/graphql"
              port = 8080

            }

            initial_delay_seconds = 30
            period_seconds        = 9
          }

          readiness_probe {
            http_get {
              path = "/graphql"
              port = 8080

            }

            initial_delay_seconds = 30
            period_seconds        = 9
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "gits_graphql_gateway" {
  metadata {
    name      = "gits-graphql-gateway"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.gits_graphql_gateway.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "NodePort"
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "gits_graphql_gateway_hpa" {
  metadata {
    name = kubernetes_deployment.gits_graphql_gateway.metadata[0].name
    namespace = var.namespace
  }

  spec {
    min_replicas = 1
    max_replicas = 10

    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment.gits_graphql_gateway.metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type = "Utilization"
          average_utilization = 300
        }
      }
    }
  }  
}