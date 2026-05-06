# # Cluster Addons Module
module "addons" {
  source = "../../../modules/addons"
  # Required variables
  region                             = "us-east-1"
  cluster_name                       = module.eks.cluster_name
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data

  # Core Cluster required addons variables
  vpc_cni_irsa_role_arn = module.iam_irsa.vpc_cni_irsa_role_arn
  # EKS Add-ons configuration
  cluster_addons = {
    vpc-cni    = { addon_version = "v1.20.1-eksbuild.3" }
    coredns    = { addon_version = "v1.12.3-eksbuild.1" }
    kube-proxy = { addon_version = "v1.34.0-eksbuild.2" }
  }
  cluster_version = module.eks.cluster_version

  # AlB Controller variables
  alb_controller_role_arn = module.iam_irsa.alb_controller_role_arn

  # ArgoCD variables
  argocd_role_arn = module.iam_irsa.argocd_role_arn
  argocd_hostname = "argocd.local"

  # Grafana variables
  grafana_secret_name      = "grafana-user-passwd"
  grafana_irsa_arn         = module.iam_irsa.grafana_irsa_arn
  prometheus_stack_version = "56.7.0"

  # Slack Webhook for Alertmanager variable
  slack_webhook_secret_name = "slack-webhook-alertmanager"

  # Ebs variables
  ebs_csi_role_arn = module.iam_irsa.ebs_csi_role_arn

  # RBAC ClusterRoleBinding for Terraform
  terraform_role_arn = "arn:aws:iam::651706774390:role/microservices-project-dev-tf-role"
  
  depends_on = [module.eks]

}
