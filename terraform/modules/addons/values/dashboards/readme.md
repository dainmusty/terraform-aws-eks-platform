resource "kubernetes_config_map_v1" "grafana_cpu_dashboard" {
  metadata {
    name      = "grafana-cpu-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "cpu-dashboard.json" = file("${path.module}/values/dashboards/cpu-dashboard.json")
  }
}

# Memory Dashboard ConfigMap
resource "kubernetes_config_map_v1" "grafana_memory_dashboard" {
  metadata {
    name      = "grafana-memory-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "memory-dashboard.json" = file("${path.module}/values/dashboards/memory-dashboard.json")
  }
}

# Pod Status Dashboard ConfigMap
resource "kubernetes_config_map_v1" "grafana_pod_status_dashboard" {
  metadata {
    name      = "grafana-pod-status-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "pod-status-dashboard.json" = file("${path.module}/values/dashboards/pod-status-dashboard.json")
  }
}

resource "kubernetes_config_map" "grafana_combined_dashboard" {
  metadata {
    name      = "grafana-combined-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "combined-dashboard.json" = file("${path.module}/values/dashboards/combined-dashboard.json")
  }
}
# terraform apply -target=kubernetes_config_map.grafana_dashboards
