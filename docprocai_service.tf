resource "kubernetes_deployment" "gits_docprocai_service" {
  depends_on = [helm_release.docprocai_service_db, helm_release.dapr, helm_release.keel]
  metadata {
    name = "gits-docprocai-service"
    labels = {
      app = "gits-docprocai-service"
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
        app = "gits-docprocai-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "gits-docprocai-service"
        }
        annotations = {
          "dapr.io/enabled"   = true
          "dapr.io/enable-metrics" = true
          "dapr.io/app-id"    = "docprocai-service"
          "dapr.io/app-port"  = 9901
          "dapr.io/http-port" = 9900
        }
      }

      spec {
        container {
          image             = "ghcr.io/meitrex/docprocai_service:latest"
          image_pull_policy = "Always"

          name = "gits-docprocai-service"

          resources {
            limits = {
              cpu    = "1.5"
              memory = "4Gi"
            }
            requests = {
              cpu    = "1"
              memory = "2Gi"
            }
          }

          env {
            name  = "SPRING_DATASOURCE_URL"
            value = "jdbc:postgresql://docprocai-service-db-postgresql:5432/docprocai-service"
          }

          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "gits"
          }

          env {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = random_password.docprocai_service_db_pass.result
          }

          env {
            name = "media_service_url"
            value = "http://localhost:3500/v1.0/invoke/media-service/method/graphql"
          }

          env {      
            name  = "connection_string"
            value = "user=gits password=${random_password.docprocai_service_db_pass.result} host=docprocai-service-db-postgresql port=5432 dbname=docprocai-service"
          }
        }
      }
    }
  }
}

resource "random_password" "docprocai_service_db_pass" {
  length  = 32
  special = false
}

resource "helm_release" "docprocai_service_db" {
  name       = "docprocai-service-db"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  namespace  = var.namespace

  set {
    name  = "global.postgresql.auth.database"
    value = "docprocai-service"
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
    value = random_password.docprocai_service_db_pass.result
  }
}
