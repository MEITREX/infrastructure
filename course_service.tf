resource "kubernetes_deployment" "gits_course_service" {
  depends_on = [helm_release.course_service_db, helm_release.dapr, helm_release.keel]
  metadata {
    name = "gits-course-service"
    labels = {
      app = "gits-course-service"
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
        app = "gits-course-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "gits-course-service"
        }
        annotations = {
          "dapr.io/enabled"                = true
          "dapr.io/enable-metrics"         = true
          "dapr.io/app-id"                 = "course-service"
          "dapr.io/app-port"               = 2001
          "dapr.io/http-port"              = 2000
          "dapr.io/sidecar-cpu-request"    = "100m"
          "dapr.io/sidecar-cpu-limit"      = "200m"
          "dapr.io/sidecar-memory-request" = "100Mi"
          "dapr.io/sidecar-memory-limit"   = "200Mi"
          "dapr.io/env"                    = "GOMEMLIMIT=180MiB"
        }
      }

      spec {
        container {
          image             = "ghcr.io/meitrex/course_service:latest"
          image_pull_policy = "Always"

          name = "gits-course-service"

          resources {
            requests = {
              cpu    = "100m"
              memory = "500Mi"
            }
          }

          env {
            name  = "SPRING_DATASOURCE_URL"
            value = "jdbc:postgresql://course-service-db-postgresql:5432/course-service"
          }

          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "gits"
          }

          env {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = random_password.course_service_db_pass.result
          }

          liveness_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = 2001

            }

            initial_delay_seconds = 30
            period_seconds        = 9
          }

          readiness_probe {
            http_get {
              path = "/actuator/health/readiness"
              port = 2001

            }

            initial_delay_seconds = 30
            period_seconds        = 9
          }
        }
      }
    }
  }
}

resource "random_password" "course_service_db_pass" {
  length  = 32
  special = false
}

resource "helm_release" "course_service_db" {
  name       = "course-service-db"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  namespace  = var.namespace

  set {
    name  = "global.postgresql.auth.database"
    value = "course-service"
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
    value = random_password.course_service_db_pass.result
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "gits_course_service_hpa" {
  metadata {
    name      = kubernetes_deployment.gits_course_service.metadata[0].name
    namespace = var.namespace
  }

  spec {
    min_replicas = 1
    max_replicas = 10

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.gits_course_service.metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 300
        }
      }
    }
  }
}
