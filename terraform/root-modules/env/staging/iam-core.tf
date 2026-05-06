# # IAM Module
module "iam_core" {
  source = "../../../modules/iam/core"

  # Resource Tags
  env          = "dev"
  company_name = "company-name"

  # Role Services Allowed
  admin_role_principals          = ["ec2.amazonaws.com", "cloudwatch.amazonaws.com", "config.amazonaws.com", "apigateway.amazonaws.com", "ssm.amazonaws.com"] # Only include the services that actually need to assume the role.
  prometheus_role_principals     = ["ec2.amazonaws.com"]
  grafana_role_principals        = ["ec2.amazonaws.com"]
  s3_rw_role_principals          = ["ec2.amazonaws.com"]
  config_role_principals         = ["config.amazonaws.com"]
  s3_full_access_role_principals = ["ec2.amazonaws.com"]


  # Instance Profile Names
  #rbac_instance_profile_name        = "dev-rbac-instance-profile"


  # S3 Buckets Referenced
  log_bucket_arn        = module.s3.operations_bucket_arn
  operations_bucket_arn = module.s3.log_bucket_arn
  log_bucket_name       = module.s3.log_bucket_name
}
