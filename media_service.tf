resource "kubernetes_deployment" "gits_media_service" {
  depends_on = [helm_release.media_service_db, helm_release.dapr, helm_release.keel, helm_release.minio]
  metadata {
    name = "gits-media-service"
    labels = {
      app = "gits-media-service"
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
        app = "gits-media-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "gits-media-service"
        }
        annotations = {
          "dapr.io/enabled"   = true
          "dapr.io/app-id"    = "media-service"
          "dapr.io/app-port"  = 3001
          "dapr.io/http-port" = 3000
          "dapr.io/sidecar-cpu-request" = "100m"
          "dapr.io/sidecar-cpu-limit"   = "200m"
          "dapr.io/sidecar-memory-request" = "100Mi"
          "dapr.io/sidecar-memory-limit"   = "200Mi"
          "dapr.io/env" = "GOMEMLIMIT=180MiB"
        }
      }

      spec {
        container {
          image             = "ghcr.io/meitrex/media_service:latest"
          image_pull_policy = "Always"

          name = "gits-media-service"

          resources {
            requests = {
              cpu    = "100m"
              memory = "500Mi"
            }
          }

          env {
            name  = "SPRING_DATASOURCE_URL"
            value = "jdbc:postgresql://media-service-db-postgresql:5432/media-service"
          }

          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "gits"
          }

          env {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = random_password.media_service_db_pass.result
          }

          env {
            name  = "MINIO_URL"
            value = "http://minio:9000"
          }
                    env {
            name  = "MINIO_PORT"
            value = "9000"
          }
          env {
            name  = "MINIO_EXTERNAL_URL"
            value = "minio.meitrex.de"
          }
          env {
            name  = "MINIO_EXTERNAL_PORT"
            value = "9000"
          }
          env {
            name  = "MINIO_ACCESS_KEY"
            value = "gits"
          }
          env {
            name  = "MINIO_ACCESS_SECRET"
            value = random_password.media_service_minio_pass.result
          }

           liveness_probe {
             http_get {
               path = "/actuator/health/liveness"
               port = 3001

             }

             initial_delay_seconds = 30
             period_seconds        = 9
           }

           readiness_probe {
             http_get {
               path = "/actuator/health/readiness"
               port = 3001

             }

             initial_delay_seconds = 30
             period_seconds        = 9
           }
        }
      }
    }
  }
}

resource "random_password" "media_service_db_pass" {
  length  = 32
  special = false
}

resource "helm_release" "media_service_db" {
  name       = "media-service-db"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  namespace  = var.namespace

  set {
    name  = "global.postgresql.auth.database"
    value = "media-service"
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
    value = random_password.media_service_db_pass.result
  }
}


resource "random_password" "media_service_minio_pass" {
  length  = 32
  special = false
}

resource "helm_release" "minio" {
  name       = "minio"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "minio"
  version    = "16.0.10"
  namespace  = var.namespace

  set {
    name  = "auth.rootUser"
    value = "gits"
  }

  set {
    name  = "auth.rootPassword"
    value = random_password.media_service_minio_pass.result
  }
  set {
    name  = "extraEnvVars[0].name"
    value = "MINIO_BROWSER_REDIRECT_URL"
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "gits_media_service_hpa" {
  metadata {
    name = kubernetes_deployment.gits_media_service.metadata[0].name
    namespace = var.namespace
  }

  spec {
    min_replicas = 1
    max_replicas = 10

    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment.gits_media_service.metadata[0].name
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