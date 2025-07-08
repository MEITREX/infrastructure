resource "helm_release" "prometheus-stack" {
  depends_on = [kubernetes_secret.dapr-scrape-config]
  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "75.4.0"
  namespace  = "prometheus-operator"

  set {
    name  = "prometheus.prometheusSpec.scrapeInterval"
    value = "30s"
  }
  
  set {
    name  = "prometheus.prometheusSpec.evaluationInterval"
    value = "30s"
  }

  set {
    name  = "prometheus.prometheusSpec.additionalScrapeConfigsSecret.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.prometheusSpec.additionalScrapeConfigsSecret.name"
    value = "prometheus-dapr-cfg"
  }

  set {
    name  = "prometheus.prometheusSpec.additionalScrapeConfigsSecret.key"
    value = "prometheus.yml"
  }
  
  set {
    name = "grafana.persistence.enabled"
    value = "true"
  }
}

resource "kubernetes_secret" "dapr-scrape-config" {
  metadata {
    name = "prometheus-dapr-cfg"
    namespace = "prometheus-operator"

  }
  type = "generic"
  data = {
    "prometheus.yml" = <<-EOT
  - job_name: dapr-sidecars
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - action: keep
        regex: "true"
        source_labels:
          - __meta_kubernetes_pod_annotation_dapr_io_enabled
      - action: keep
        regex: "true"
        source_labels:
          - __meta_kubernetes_pod_annotation_dapr_io_enable_metrics
      - action: replace
        replacement: $${1}
        source_labels:
          - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        replacement: $${1}
        source_labels:
          - __meta_kubernetes_pod_name
        target_label: pod
      - action: replace
        regex: (.*);daprd
        replacement: $${1}-dapr
        source_labels:
          - __meta_kubernetes_pod_annotation_dapr_io_app_id
          - __meta_kubernetes_pod_container_name
        target_label: service
      - action: replace
        replacement: $${1}:9090
        source_labels:
          - __meta_kubernetes_pod_ip
        target_label: __address__

  - job_name: dapr
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - action: keep
        regex: dapr
        source_labels:
          - __meta_kubernetes_pod_label_app_kubernetes_io_name
      - action: keep
        regex: dapr
        source_labels:
          - __meta_kubernetes_pod_label_app_kubernetes_io_part_of
      - action: replace
        replacement: $${1}
        source_labels:
          - __meta_kubernetes_pod_label_app
        target_label: app
      - action: replace
        replacement: $${1}
        source_labels:
          - __meta_kubernetes_namespace
        target_label: namespace
      - action: replace
        replacement: $${1}
        source_labels:
          - __meta_kubernetes_pod_name
        target_label: pod
      - action: replace
        replacement: $${1}:9090
        source_labels:
          - __meta_kubernetes_pod_ip
        target_label: __address__  
      EOT
  }
}