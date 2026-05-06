# IAM Module
module "iam_irsa" {
  source = "../../../modules/iam/irsa"

  # addons variables
  grafana_secret_name = "grafana-user-passwd"
  cluster_auth        = module.eks.cluster_certificate_authority_data
  cluster_name        = module.eks.cluster_name
  oidc_issuer         = module.eks.oidc_issuer
  oidc_provider_url   = module.eks.oidc_provider_url

}
