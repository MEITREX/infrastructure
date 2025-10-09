resource "kubernetes_deployment" "gits_notification_service" {
  depends_on = [helm_release.notification_service_db, helm_release.dapr, helm_release.keel]
  metadata {
    name = "gits-notification-service"
    labels = {
      app = "gits-notification-service"
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
        app = "gits-notification-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "gits-notification-service"
        }
        annotations = {
          "dapr.io/enabled"        = true
          "dapr.io/enable-metrics" = true
          "dapr.io/app-id"         = "notification-service"
          "dapr.io/app-port"       = 3101
          "dapr.io/http-port"      = 3100
        }
      }

      spec {
        container {
          image             = "ghcr.io/meitrex/notification_service:latest"
          image_pull_policy = "Always"

          name = "gits-notification-service"

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
            value = "jdbc:postgresql://notification-service-db-postgresql:5432/notification-service"
          }

          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "gits"
          }

          env {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = random_password.notification_service_db_pass.result
          }

          env {
            name  = "COURSE_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/course-service/method/graphql"
          }

          env {
            name  = "USER_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/user-service/method/graphql"
          }

          liveness_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = 3101

            }

            initial_delay_seconds = 30
            period_seconds        = 9
          }

          readiness_probe {
            http_get {
              path = "/actuator/health/readiness"
              port = 3101

            }

            initial_delay_seconds = 30
            period_seconds        = 9
          }
        }
      }
    }
  }
}

resource "random_password" "notification_service_db_pass" {
  length  = 32
  special = false
}

resource "helm_release" "notification_service_db" {
  name       = "notification-service-db"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  namespace  = var.namespace

  set {
    name  = "global.postgresql.auth.database"
    value = "notification-service"
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
    value = random_password.notification_service_db_pass.result
  }
}
