# Create Kubernetes Service Account for Grafana
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Create Kubernetes Service Account for Grafana
resource "kubernetes_service_account_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = var.grafana_irsa_arn
    }
  }
}


data "aws_secretsmanager_secret_version" "grafana_admin" {
  secret_id = var.grafana_secret_name
}

locals {
  grafana_secret = jsondecode(data.aws_secretsmanager_secret_version.grafana_admin.secret_string)
}

resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = "grafana-admin"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  data = {
    admin-user     = local.grafana_secret.username
    admin-password = local.grafana_secret.password
  }

  type = "Opaque"
}


# Install the CRDs for kube-prometheus-stack first
resource "helm_release" "kube_prometheus_crds" {
  name      = "kube-prometheus-crds"
  namespace = kubernetes_namespace_v1.monitoring.metadata[0].name

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version   = var.prometheus_stack_version

  values = [
    <<EOF
crds:
  enabled: true

alertmanager:
  enabled: false
prometheus:
  enabled: false
grafana:
  enabled: false
kubeStateMetrics:
  enabled: false
nodeExporter:
  enabled: false
EOF
  ]

  wait    = true
  timeout = 300
}


# Deploys the kube-prometheus-stack Helm chart for monitoring(Prometheus, Grafana, etc.)
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  namespace        = kubernetes_namespace_v1.monitoring.metadata[0].name
  create_namespace = false

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_stack_version

  # 🔑 Stability flags (kept)
  wait            = true
  timeout         = 900
  cleanup_on_fail = true
  force_update    = true
  recreate_pods   = true

  values = [
    templatefile("${path.module}/values/grafana-service.yaml", {
      region               = var.region
      grafana_admin_secret = kubernetes_secret_v1.grafana_admin.metadata[0].name
    }),

    file("${path.module}/values/alertmanager.yaml"),
    file("${path.module}/values/grafana-dashboards.yaml"),
    file("${path.module}/values/prometheus_rules.yaml")
  ]

  depends_on = [
    helm_release.kube_prometheus_crds,
    kubernetes_service_account_v1.grafana,
    kubernetes_secret_v1.grafana_admin,
    kubernetes_secret_v1.alertmanager_slack_webhook
  ]
}



data "aws_secretsmanager_secret_version" "slack_webhook" {
  secret_id = var.slack_webhook_secret_name
}

resource "kubernetes_secret_v1" "alertmanager_slack_webhook" {
  metadata {
    name      = "alertmanager-slack-webhook"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  data = {
    slack_url = jsondecode(data.aws_secretsmanager_secret_version.slack_webhook.secret_string)["url"]
  }

  type = "Opaque"
}

