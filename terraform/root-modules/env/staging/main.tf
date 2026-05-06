# # # VPC Module
# module "vpc" {
#   source = "../../modules/vpc"

#   vpc_cidr              = "10.1.0.0/16"
#   ResourcePrefix        = "GNPC-Dev"
#   enable_dns_hostnames  = true
#   enable_dns_support    = true
#   instance_tenancy      = "default"
#   public_subnet_cidr    = ["10.1.1.0/24", "10.1.2.0/24"] 
#   private_subnet_cidr   = ["10.1.3.0/24", "10.1.4.0/24"] 
#   availability_zones    = ["us-east-1a", "us-east-1b"]
#   public_ip_on_launch   = true
#   PublicRT_cidr         = "0.0.0.0/0"
#   cluster_name          = "effulgencetech-dev"
#   PrivateRT_cidr        = "0.0.0.0/0"
#   eip_associate_with_private_ip = true
# }


# # Security Groups Module
# module "security_group" {
#   source      = "../../modules/security"
#   vpc_id      = module.vpc.vpc_id
#   ResourcePrefix = "GNPC-Dev"
#   public_sg_description = "Security group for public instances"

#   public_sg_ingress_rules = [
#     {
#       from_port   = 22
#       to_port     = 22
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#       description = "SSH from anywhere"
#     },
#     {
#       from_port   = 80
#       to_port     = 80
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#       description = "HTTP from anywhere"
#     },
#     {
#       from_port   = 443
#       to_port     = 443
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#       description = "HTTPS from anywhere"
#     },
#     {
#       from_port   = 9100
#       to_port     = 9100
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#       description = "HTTPS from anywhere"
#     }
#   ]

#   public_sg_egress_rules = [
#     {
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#       description = "Allow all egress"
#     }
#   ]

#   private_sg_description = "Security group for private instances"
#   private_sg_ingress_rules = [
#     {
#       from_port                = 22
#       to_port                  = 22
#       protocol                 = "tcp"
#       source_security_group_ids = [module.security_group.public_sg_id]
#       description              = "SSH from public SG"
#     }
#   ]

#   private_sg_egress_rules = [
#     {
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#       description = "Allow all outbound"
#     }
#   ]
#   monitoring_sg_ingress_rules = [
#     {
#       description = "Allow Prometheus"
#       from_port   = 9090
#       to_port     = 9090
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     },
#     {
#       description = "Allow Grafana"
#       from_port   = 3000
#       to_port     = 3000
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     },
#     {
#       description = "Allow SSH"
#       from_port   = 22
#       to_port     = 22
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   ]

  

#   monitoring_sg_egress_rules = [
#     {
#       description = "Allow all outbound traffic"
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   ]
  
# }


# # # EC2 Module
# module "ec2" {
#   source = "../../modules/ec2"

#   ResourcePrefix             = "GNPC-Dev"
#   ami_ids                    = ["ami-08b5b3a93ed654d19", "ami-02a53b0d62d37a757", "ami-02e3d076cbd5c28fa", "ami-0c7af5fe939f2677f", "ami-04b4f1a9cf54c11d0"]
#   ami_names                  = ["AL2023", "AL2", "Windows", "RedHat", "ubuntu"]
#   instance_types             = ["t2.micro", "t2.micro", "t2.micro", "t2.micro", "t2.micro"]
#   key_name             = module.ssm.key_name_parameter_value
#   admin_profile_name                   = module.iam.admin_instance_profile_name
#   public_instance_count      = [0, 0, 0, 0, 0]
#   private_instance_count     = [0, 0, 0, 0, 0]

#   tag_value_public_instances = [
#     [
#       {
#         Name        = "app_servers"
#         Environment = "Dev"
#       },
      
#     ],
#     [], [], [], []
#   ]

#   tag_value_private_instances = [
#     [],
#     [
#       {
#         Name = "db1"
#         Tier = "Database"
#       }
#     ],
#     [],
#     [], []
#   ]

#   vpc_id                     = module.vpc.vpc_id
#   public_subnet_ids          = module.vpc.vpc_public_subnets
#   private_subnet_ids         = module.vpc.vpc_private_subnets
#   public_sg_id               = module.security_group.public_sg_id
#   private_sg_id              = module.security_group.private_sg_id
#   volume_size                = 8
#   volume_type                = "gp3"
# }

# # # IAM Module
# module "iam" {
#   source = "../../modules/iam"

#   # Resource Tags
#   env          = "dev"
  
#   company_name = "GNPC"

#   # Role Services Allowed
#   admin_role_principals          = ["ec2.amazonaws.com", "cloudwatch.amazonaws.com", "config.amazonaws.com", "apigateway.amazonaws.com", "ssm.amazonaws.com"]  # Only include the services that actually need to assume the role.
#   prometheus_role_principals     = ["ec2.amazonaws.com"]
#   grafana_role_principals        = ["ec2.amazonaws.com"]
#   s3_rw_role_principals          = ["ec2.amazonaws.com"]
#   config_role_principals         = ["config.amazonaws.com"]
#   s3_full_access_role_principals = ["ec2.amazonaws.com"]

#   # Permission Boundaries
#   admin_permissions_boundary_arn         = module.iam.permission_boundary_arn   # If you are not required to apply the permission boundary, then your value will be "null"
#   config_permissions_boundary_arn        = module.iam.permission_boundary_arn
#   s3_full_access_permissions_boundary_arn = module.iam.permission_boundary_arn
#   s3_rw_permissions_boundary_arn         = module.iam.permission_boundary_arn
#   grafana_permissions_boundary_arn       = module.iam.permission_boundary_arn
#   prometheus_permissions_boundary_arn    = module.iam.permission_boundary_arn
#   eks_node_permissions_boundary_arn      = module.iam.permission_boundary_arn
#   eks_cluster_permissions_boundary_arn   = module.iam.permission_boundary_arn   # If you are not required to apply the permission boundary, then your value will be "null"

#   # S3 Buckets Referenced
#   log_bucket_arn        = module.s3.operations_bucket_arn
#   operations_bucket_arn = module.s3.log_bucket_arn

#   # addons variables
#   oidc_provider_arn     = module.eks.oidc_provider_arn
#   grafana_secret_name   = "grafana-user-passwd"
#   cluster_name = module.eks.cluster_name

# }





# # # S3 Module
# module "s3" {
#   source                          = "../../modules/s3"
#   config_bucket_name = module.s3.config_bucket_name
#   config_key_prefix = "config-logs"
#   config_role_arn = module.iam.config_role_arn
#   log_bucket_name                      = "gnpc-dev-log-bucket"
#   operations_bucket_name          = "gnpc-devoperations-bucket"
#   replication_bucket_name = "gnpc-replication-bucket"
#   log_bucket_versioning_status = "Enabled"
#   operations_bucket_versioning_status    = "Enabled"
#   replication_bucket_versioning_status   = "Enabled"
#   logging_prefix                  = "logs/"
#   ResourcePrefix                  = "GNPC-Dev"
#   tags                            = {
#     Environment = "dev"
#     Project     = "GNPC"
#   }
# }



# # # AWS Config Module
# # module "config_rules" {
# #   source = "../../modules/compliance"
# #   config_role_arn           = module.iam.config_role_arn
# #   config_bucket_name     = module.s3.log_bucket_name  # This is the bucket where AWS Config stores configuration history and snapshot files. The config bucket is actually the log bucket.
# #   config_s3_key_prefix      = "config-logs"

# #   recorder_status_enabled               = true 
# #   recording_gp_all_supported            = true 
# #   recording_gp_global_resources_included = true 

# #   config_rules = [
# #     {
# #       name              = "restricted-incoming-traffic"
# #       source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
# #     },
# #     {
# #       name              = "required-tags"
# #       source_identifier = "REQUIRED_TAGS"
# #       input_parameters  = jsonencode({ tag1Key = "Owner", tag2Key = "Environment" })
# #       compliance_resource_types = ["AWS::EC2::Instance"]
# #     },
# #     {
# #       name              = "dev-s3-public-read-prohibited"
# #       source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
# #     },
# #     {
# #       name              = "dev-cloudtrail-enabled"
# #       source_identifier = "CLOUD_TRAIL_ENABLED"
# #     }
# #   ]
# # }


# module "monitoring" {
#   source               = "../../modules/monitoring"   # This has the instances for Prometheus and Grafana
#   vpc_id               = module.vpc.vpc_id
#   ami                  = "ami-08b5b3a93ed654d19" 
#   instance_type        = "t2.micro"
#   subnet_id            = module.vpc.vpc_public_subnets[0]
#   security_group_ids   = [module.security_group.monitoring_sg_id]
#   ResourcePrefix       = "GNPC-Dev"
#   key_name             = module.ssm.key_name_parameter_value
#   monitoring_sg_id = module.security_group.monitoring_sg_id
#   prometheus_profile_name = module.iam.prometheus_instance_profile_name
#   grafana_profile_name    = module.iam.grafana_instance_profile_name
#   aws_region                  = "us-east-1"
#   prometheus_tags = {
#   Name        = "Prometheus"
#   Environment = "Dev"
# }

# grafana_tags = {
#   Name        = "Grafana"
#   Environment = "Dev"
# }
# }



# module "eks" {
#   source                  = "../../modules/eks"
#   region                  = "us-east-1"
#   vpc_cidr                = "192.168.0.0/16"
#   public_subnet_1_cidr    = "192.168.32.0/19"
#   public_subnet_2_cidr    = "192.168.0.0/19"
#   private_subnet_1_cidr   = "192.168.96.0/19"
#   private_subnet_2_cidr   = "192.168.64.0/19"
#   availability_zone_1     = "us-east-1f"
#   availability_zone_2     = "us-east-1b"
#   availability_zone_3     = "us-east-1d"
#   availability_zone_4     = "us-east-1a"

#   cluster_name            = "effulgencetech-dev"
#   kube_version            = "1.32"
#   node_group_name         = "dev-nodegroup"
#   instance_type           = "t2.medium"
#   ami_type                = "AL2_x86_64"
#   desired_capacity        = 2
#   min_size                = 1
#   max_size                = 3
#   volume_size             = 80
#   volume_iops             = 3000
#   volume_throughput       = 125
# }

# # # module "rds" {
# # #   source = "../../modules/rds"
# # #   identifier = "gnpc-dev-db"
# # #   db_engine = "postgres"
# # #   db_engine_version = "15.5" # check for the latest version
# # #   instance_class = "db.t3.micro"
# # #   allocated_storage = 10
# # #   db_name = "mydb"
# # #   username = module.ssm.db_access_parameter_value
# # #   password = module.ssm.db_secret_parameter_value
# # #   subnet_ids = module.vpc.vpc_private_subnets
# # #   vpc_security_group_ids = [module.security_group.private_sg_id]
# # #   db_subnet_group_name = "rds-subnet-group"
# # #   multi_az = false
# # #   storage_type = "gp2"
# # #   backup_retention_period = 7
# # #   skip_final_snapshot = true
# # #   publicly_accessible = false
# # #   env = "dev"
# # #   db_tags = {
# # #     Name        = "rds-instance"
# # #     Environment = "Dev"
# # #     Owner       = "Musty"
# # #   }
# # # }



# module "ssm" {
#   source         = "../../modules/ssm"
#   db_access_parameter_name  = "/db/access"
#   db_secret_parameter_name  = "/db/secure/access"
#   key_path_parameter_name   = "/kp/path"
#   key_name_parameter_name   = "/kp/name"
#   grafana_admin_password    = "/grafana/admin/password"
# }

# # module "secrets" {
# #   source         = "../../modules/secrets"
 
# # }



# # # Addons Module
# module "addons" {
#   source            = "../../modules/addons"
#   # Required variables
#   region            = "us-east-1"
#   cluster_name      = module.eks.cluster_name

#   alb_controller_role = module.iam.alb_controller_role

#   # ArgoCD variables
#   argocd_role_arn   = module.iam.argocd_role_arn
#   argocd_hostname   = "argocd.local"

#   # Grafana variables
#   grafana_secret_name     = "grafana-user-passwd"
#   grafana_irsa_arn = module.iam.grafana_irsa_arn

#   # Slack Webhook for Alertmanager variable
#   slack_webhook_secret_name = "slack-webhook-alertmanager"

#   # Ebs variables
#   ebs_csi_role_arn = module.iam.ebs_csi_role_arn
  
# }














