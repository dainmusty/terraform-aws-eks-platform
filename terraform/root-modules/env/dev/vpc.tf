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
