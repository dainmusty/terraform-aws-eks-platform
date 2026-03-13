# CPU Dashboard ConfigMap
resource "kubernetes_config_map_v1" "grafana_dashboards" {
  metadata {
    name      = "grafana-dashboards"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    for file in fileset("${path.module}/values/dashboards", "*.json") :
    file => file("${path.module}/values/dashboards/${file}")
  }
}
