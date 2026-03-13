variable "ResourcePrefix" {
  description = "Prefix for naming resources."
  type        = string
}

variable "key_name" {
  description = "The name of the key pair to use for EC2 instances."
  type        = string
}

# variable "instance_profile_name" {
#   description = "The IAM instance profile name for EC2 instances."
#   type        = string
# }

variable "ami_ids" {
  description = "List of AMI IDs for EC2 instances."
  type        = list(string)
}

variable "ami_names" {
  description = "List of names for EC2 instances."
  type        = list(string)
}

variable "instance_types" {
  description = "List of instance types for EC2 instances."
  type        = list(string)
}

variable "public_instance_count" {
  description = "List of instance counts for public EC2 instances."
  type        = list(number)
}

variable "private_instance_count" {
  description = "List of instance counts for private EC2 instances."
  type        = list(number)
}

variable "tag_value_public_instances" {
  description = "List of additional tags for public EC2 instances."
  type        = list(list(map(string)))
}

variable "tag_value_private_instances" {
  description = "List of additional tags for private EC2 instances."
  type        = list(list(map(string)))
}

variable "vpc_id" {
  description = "The ID of the VPC where the EC2 instances will be launched."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for EC2 instances."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EC2 instances."
  type        = list(string)
}

variable "public_sg_id" {
  description = "ID of the public security group."
  type        = string
}

variable "private_sg_id" {
  description = "ID of the private security group."
  type        = string
}


variable "volume_size" {
  description = "Size of the root volume in GB."
  type        = number
}

variable "volume_type" {
  description = "Type of the root volume (e.g., gp2, gp3, io1)."
  type        = string
}
