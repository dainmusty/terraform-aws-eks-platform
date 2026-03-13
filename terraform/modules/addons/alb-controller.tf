# 1. Create IRSA-enabled Service Account
resource "kubernetes_service_account_v1" "alb_controller_sa" {
  metadata {
    name      = "aws-load-balancer-controller"  # AWS Load Balancer Controller expects this exact name for the service account
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = var.alb_controller_role_arn
    }
  }
}


# 2. Install AWS Load Balancer Controller via Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account_v1.alb_controller_sa.metadata[0].name
  }

  depends_on = [
    kubernetes_service_account_v1.alb_controller_sa
  ]
}


