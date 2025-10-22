resource "kubernetes_deployment" "gits_tutor_service" {
  depends_on = [helm_release.tutor_service_db, helm_release.dapr, helm_release.keel]
  metadata {
    name = "gits-tutor-service"
    labels = {
      app = "gits-tutor-service"
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
        app = "gits-tutor-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "gits-tutor-service"
        }
        annotations = {
          "dapr.io/enabled"        = true
          "dapr.io/enable-metrics" = true
          "dapr.io/app-id"         = "tutor-service"
          "dapr.io/app-port"       = 1301
          "dapr.io/http-port"      = 1300
        }
      }

      spec {
        container {
          image             = "ghcr.io/meitrex/tutor_service:latest"
          image_pull_policy = "Always"

          name = "gits-tutor-service"

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
            value = "jdbc:postgresql://tutor-service-db-postgresql:5432/tutor-service"
          }

          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "gits"
          }

          env {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = random_password.tutor_service_db_pass.result
          }

          env {
            name  = "CONTENT_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/content-service/method/graphql"
          }

          env {
            name  = "DOCPROC_URL"
            value = "http://localhost:3500/v1.0/invoke/docprocai-service/method/graphql/"
          }

          liveness_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = 1301

            }

            initial_delay_seconds = 30
            period_seconds        = 9
          }

          readiness_probe {
            http_get {
              path = "/actuator/health/readiness"
              port = 1301

            }

            initial_delay_seconds = 30
            period_seconds        = 9
          }
        }
      }
    }
  }
}

resource "random_password" "tutor_service_db_pass" {
  length  = 32
  special = false
}

resource "helm_release" "tutor_service_db" {
  name       = "tutor-service-db"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  namespace  = var.namespace

  set {
    name  = "global.postgresql.auth.database"
    value = "tutor-service"
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
    value = random_password.tutor_service_db_pass.result
  }
}
