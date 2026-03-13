# EKS Access Variables
variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  
}
variable "eks_access_entry_policies" {
  description = "EKS Access Entry Policies"
  type        =  string
}

variable "eks_access_principal_arn" {
  description = "eks access principal arn"
  type = string
}

variable "node_access_policies" {
  description = "node access policies"
  type = string
}

variable "console_user_access" {
  description = "console user access to cluster"
  type = string
}