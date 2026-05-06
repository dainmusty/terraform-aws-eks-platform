# # S3 Module
module "s3" {
  source = "../../../modules/s3"

  # S3 Bucket Names
  log_bucket_name         = "dev-enterprise-log-bucket"
  operations_bucket_name  = "dev-enterprise-operations-bucket"
  replication_bucket_name = "dev-enterprise-replication-bucket"

  # Versioning Status
  log_bucket_versioning_status         = "Enabled"
  operations_bucket_versioning_status  = "Enabled"
  replication_bucket_versioning_status = "Enabled"

  # Logging Prefix
  logging_prefix = "logs/"
  ResourcePrefix = "Dev-Enterprise"

  tags = {
    Environment = "dev"
    Project     = "GNPC"
  }
}
