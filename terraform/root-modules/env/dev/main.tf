provider "aws" {
  region = "us-east-1"
  #profile = "default"

}

# Needed for ACM certs with CloudFront 
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}



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



module "vpc" {
  source = "../../../modules/vpc"


  vpc_cidr             = "10.1.0.0/16"
  ResourcePrefix       = "GNPC-Dev"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  public_subnet_cidr   = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidr  = ["10.1.3.0/24", "10.1.4.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_ip_on_launch  = true
  PublicRT_cidr        = "0.0.0.0/0"
  cluster_name         = "effulgencetech-dev"
  PrivateRT_cidr       = "0.0.0.0/0"

  tags = {
    Environment = "Dev"
    Project     = "Startup"
  }
  # 🔽 Flow logs config
  enable_flow_logs           = true # Enable VPC flow logs
  flow_logs_destination_type = "s3" # change to "cloud-watch-logs" if using CloudWatch Logs
  flow_logs_destination      = module.s3.log_bucket_arn
  flow_logs_traffic_type     = "ALL" # ACCEPT → capture only accepted traffic. # REJECT → capture only rejected traffic. ALL → capture all traffic.
  vpc_flow_log_iam_role_arn  = null  # Provide iam role if using CloudWatch Logs
  env                        = "dev"
  enable_nat_gateway         = true


}



# Bastion SG
module "bastion_sg" {
  source = "../../../modules/security/bastion"
  vpc_id = module.vpc.vpc_id
  env    = "Dev"

  bastion_ingress_rules = [
    {
      description = "Allow traffic from the internet"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  bastion_egress_rules = [
    {
      description = "Allow all egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  bastion_sg_tags = {
    Name        = "bastion-sg"
    Environment = "Dev"
  }

}


# Private SG - Use this a private EKS SG 
module "cluster_sg" {
  source = "../../../modules/security/private-sg" # Remember to change name from private to cluster sg.
  vpc_id = module.vpc.vpc_id
  env    = "Dev"

  ingress_rules = [
    {
      description               = "Allow traffic from bastion"
      from_port                 = 22
      to_port                   = 22
      protocol                  = "tcp"
      source_security_group_ids = [module.bastion_sg.bastion_sg_id]
    },
    {
      description               = "Allow traffic from bastion"
      from_port                 = 443
      to_port                   = 443
      protocol                  = "tcp"
      source_security_group_ids = [module.bastion_sg.bastion_sg_id]
    }
  ]

  egress_rules = [
    {
      description = "Allow all egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  cluster_sg_tags = {
    Name        = "cluster-sg"
    Environment = "Dev"
  }

}


# Public SG - Use this a public EKS SG
module "node_sg" {
  source = "../../../modules/security/public-sg"
  vpc_id = module.vpc.vpc_id
  env    = "Dev"

  ingress_rules = [

    # Node-to-node traffic
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      self        = true
      description = "Allow all node-to-node traffic"
    },

    # Kubelet API from control plane
    {
      from_port       = 10250
      to_port         = 10250
      protocol        = "tcp"
      security_groups = [module.cluster_sg.cluster_sg_id]
      description     = "Allow kubelet API from control plane"
    },
    {
      description     = "Allow control plane to reach nodes"
      from_port       = 0
      to_port         = 65535
      protocol        = "tcp"
      security_groups = [module.cluster_sg.cluster_sg_id]
    }

  ]

  # allow node -> anywhere egress
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]


  node_sg_tags = {
    Name        = "node-sg"
    Environment = "Dev"
  }

}



# # EC2 Module
module "ec2" {
  source = "../../../modules/ec2"

  ResourcePrefix = "Dev"
  ami_ids        = ["ami-08b5b3a93ed654d19", "ami-02a53b0d62d37a757", "ami-02e3d076cbd5c28fa", "ami-0c7af5fe939f2677f", "ami-04b4f1a9cf54c11d0"]
  ami_names      = ["AL2023", "AL2", "Windows", "RedHat", "ubuntu"]
  instance_types = ["t2.micro", "t2.micro", "t2.micro", "t2.micro", "t2.micro"]
  key_name       = module.ssm.key_name_parameter_value
  #instance_profile_name      = module.iam_core.rbac_instance_profile_name
  public_instance_count  = [0, 0, 0, 0, 0]
  private_instance_count = [0, 0, 0, 0, 0]


  tag_value_public_instances = [
    [
      {
        Name        = "bastion"
        Environment = "Dev"
      },

    ],
    [], [], [], []
  ]

  tag_value_private_instances = [
    [],
    [
      {
        Name = "db1"
        Tier = "Database"
      }
    ],
    [],
    [], []
  ]

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  public_sg_id       = module.bastion_sg.bastion_sg_id
  private_sg_id      = module.bastion_sg.bastion_sg_id
  volume_size        = 8
  volume_type        = "gp3"
}



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




module "eks" {
  source = "../../../modules/eks"

  # cluster variables
  cluster_name              = "effulgencetech"
  cluster_version           = "1.34"
  cluster_role              = module.iam_core.cluster_role_arn
  subnet_ids                = module.vpc.private_subnet_ids
  

  cluster_policy = [
    module.iam_core.cluster_policies
  ]

  # node group variables
  node_group_role_arn = module.iam_core.node_group_role_arn
  eks_node_policies   = module.iam_core.eks_node_policies
  dev_ng = {
    worker_nodes_config = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      scaling_config = {
        desired_size = 2
        max_size     = 3
        min_size     = 2
      }
    }

  }
}


# module "eks_access" {
#   source = "../../../modules/eks-access"

#   eks_access_principal_arn  = "arn:aws:iam::651706774390:role/microservices-project-dev-tf-role" # use data to hide account id later
#   eks_access_entry_policies = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#   node_access_policies      = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSWorkerNodePolicy"
#   console_user_access       = "arn:aws:iam::651706774390:user/musty"
#   cluster_name              = module.eks.cluster_name

# }


#  module "rds" {
# #   source = "../../modules/rds"
# #   identifier = "gnpc-dev-db"
# #   db_engine = "postgres"
# #   db_engine_version = "15.5" # check for the latest version
# #   instance_class = "db.t3.micro"
# #   allocated_storage = 10
# #   db_name = "mydb"
# #   username = module.ssm.db_access_parameter_value
# #   password = module.ssm.db_secret_parameter_value
# #   subnet_ids = module.vpc.vpc_private_subnets
# #   vpc_security_group_ids = [module.security_group.private_sg_id]
# #   db_subnet_group_name = "rds-subnet-group"
# #   multi_az = false
# #   storage_type = "gp2"
# #   backup_retention_period = 7
# #   skip_final_snapshot = true
# #   publicly_accessible = false
# #   env = "dev"
# #   db_tags = {
# #     Name        = "rds-instance"
# #     Environment = "Dev"
# #     Owner       = "Musty"
# #   }
# # }



module "ssm" {
  source                   = "../../../modules/ssm"
  db_access_parameter_name = "/db/access"
  db_secret_parameter_name = "/db/secure/access"
  key_path_parameter_name  = "/kp/path"
  key_name_parameter_name  = "/kp/name"
  grafana_admin_password   = "/grafana/admin/password"
}




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



module "app_ecr_repo" {
  source = "../../../modules/ecr"

  for_each = {
    web = "tankofm-web"
    app = "tankofm-app"
    db  = "tankofm-db"
  }

  repository_name = each.value


  image_tag_mutability = "MUTABLE"
  scan_on_push         = true

  tags = {
    Environment = "dev"
    Project     = "Push-To-ECR"
  }
}






