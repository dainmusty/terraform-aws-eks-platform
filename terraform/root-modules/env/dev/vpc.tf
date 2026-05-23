module "vpc" {
  source = "../../../modules/vpc"


  vpc_cidr             = "10.1.0.0/16"
  resource_prefix      = "gnpc-dev"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default" # default or dedicated

  public_subnet_cidrs   = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs  = ["10.1.10.0/24", "10.1.11.0/24"]
  private_db_subnet_cidrs = ["10.1.20.0/24","10.1.21.0/24"] 

  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_ip_on_launch  = true
  public_rt_cidr       = "0.0.0.0/0"
  private_rt_cidr      = "0.0.0.0/0"

  cluster_name         = "effulgencetech-dev"

  tags = {
    Environment = "dev"
    Project     = "startup"
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
