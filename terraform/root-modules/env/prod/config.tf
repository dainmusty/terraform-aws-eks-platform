# # AWS Config Module
# module "config_rules" {
#   source = "../../modules/compliance"
#   config_role_arn           = module.iam.config_role_arn
#   config_bucket_name     = module.s3.log_bucket_name  # This is the bucket where AWS Config stores configuration history and snapshot files. The config bucket is actually the log bucket.
#   config_s3_key_prefix      = "config-logs"

#   recorder_status_enabled               = true 
#   recording_gp_all_supported            = true 
#   recording_gp_global_resources_included = true 

#   config_rules = [
#     {
#       name              = "restricted-incoming-traffic"
#       source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
#     },
#     {
#       name              = "required-tags"
#       source_identifier = "REQUIRED_TAGS"
#       input_parameters  = jsonencode({ tag1Key = "Owner", tag2Key = "Environment" })
#       compliance_resource_types = ["AWS::EC2::Instance"]
#     },
#     {
#       name              = "dev-s3-public-read-prohibited"
#       source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
#     },
#     {
#       name              = "dev-cloudtrail-enabled"
#       source_identifier = "CLOUD_TRAIL_ENABLED"
#     }
#   ]
# }
