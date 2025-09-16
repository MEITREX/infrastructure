resource "kubernetes_deployment" "gits_gamification_service" {
  depends_on = [helm_release.gamification_service_db, helm_release.dapr, helm_release.keel]
  metadata {
    name = "gits-gamification-service"
    labels = {
      app = "gits-gamification-service"
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
        app = "gits-gamification-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "gits-gamification-service"
        }
        annotations = {
          "dapr.io/enabled"        = true
          "dapr.io/enable-metrics" = true
          "dapr.io/app-id"         = "gamification-service"
          "dapr.io/app-port"       = 1201
          "dapr.io/http-port"      = 1200
        }
      }

      spec {
        container {
          image             = "ghcr.io/meitrex/gamification_service:latest"
          image_pull_policy = "Always"

          name = "gits-gamification-service"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "50Mi"
            }
          }

          env {
            name  = "SPRING_DATASOURCE_URL"
            value = "jdbc:postgresql://gamification-service-db-postgresql:5432/gamification-service"
          }

          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "gits"
          }

          env {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = random_password.gamification_service_db_pass.result
          }

          env {
            name  = "CONTENT_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/content-service/method/graphql"
          }

          env {
            name  = "COURSE_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/course-service/method/graphql"
          }

          liveness_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = 1201

            }

            initial_delay_seconds = 90
            period_seconds        = 9
          }

          readiness_probe {
            http_get {
              path = "/actuator/health/readiness"
              port = 1201

            }

            initial_delay_seconds = 90
            period_seconds        = 9
          }
        }
      }
    }
  }
}

resource "random_password" "gamification_service_db_pass" {
  length  = 32
  special = false
}

resource "helm_release" "gamification_service_db" {
  name       = "gamification-service-db"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  namespace  = var.namespace

  set {
    name  = "global.postgresql.auth.database"
    value = "gamification-service"
  }

  set {
    name  = "postgres.auth.enablePostgresUser"
    value = "false"
  }

  set {
    name  = "global.postgresql.auth.username"
    value = "gits"
  }

  set {
    name  = "global.postgresql.auth.password"
    value = random_password.gamification_service_db_pass.result
  }
}
