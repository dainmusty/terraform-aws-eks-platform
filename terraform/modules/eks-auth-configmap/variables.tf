variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "bootstrap_role_arn" {
  type        = string
  description = "ARN of the bootstrap role to use for kube API authentication (will be passed to aws eks get-token --role-arn). The caller must be allowed to assume this role."
}

variable "map_roles" {
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  description = "List of role mappings to add to aws-auth.mapRoles"
  default     = []
}

variable "map_users" {
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  description = "List of user mappings to add to aws-auth.mapUsers"
  default     = []
}

variable "cluster_details" {
  type = object({
    endpoint                   = string
    certificate_authority_data = string
  })
  description = "EKS cluster connection details"
}

variable "enable_aws_auth_bootstrap" {
  description = "One-time bootstrap of aws-auth ConfigMap. Set to false after initial cluster access is established."
  type        = bool
  default     = false
}
