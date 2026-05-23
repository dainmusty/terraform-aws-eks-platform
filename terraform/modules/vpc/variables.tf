variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames for the VPC"
  type        = bool
}

variable "enable_dns_support" {
  description = "Enable DNS support for the VPC"
  type        = bool
}

variable "instance_tenancy" {
  description = "Instance tenancy for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "List of CIDR blocks for private DB subnets"
  type        = list(string)
}

variable "public_ip_on_launch" {
  description = "Enable public IP on launch for public subnets"
  type        = bool
}

variable "public_rt_cidr" {
  description = "CIDR block for the public route table"
  type        = string
}

variable "private_rt_cidr" {
  description = "CIDR block for the private route table"
  type        = string
  
}
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}



# Variables for flow logs and default security gp.
variable "enable_flow_logs" {
  type    = bool
  default = true
}

variable "flow_logs_destination" {
  type        = string
  description = "ARN of S3 bucket or CloudWatch Logs group"
}

variable "flow_logs_destination_type" {
  type        = string
  description = "S3 or cloud-watch-logs"
  default     = "cloud-watch-logs"
}

variable "flow_logs_traffic_type" {
  type        = string
  description = "ACCEPT, REJECT, or ALL"
  default     = "ALL"
}

variable "vpc_flow_log_iam_role_arn" {
  type        = string
  description = "IAM role ARN for flow logs if using CloudWatch"
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "env" {
  description = "Environment"
  type = string
  
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway and EIP"
  type        = bool
  default     = true
}
