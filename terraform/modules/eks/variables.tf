# Cluster Variables
variable "cluster_name" {
  description = "The name of my EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "My cluster version"
  type        = string
}

variable "cluster_role" {
  description = "EKS Cluster Role ARN"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "cluster_policy" {
  description = "EKS Cluster Policy Attachment"
  type        = any
}


# Node Group Variables
variable "dev_ng" {
  description = "EKS node group configuration variable"

  type = map(
    object({
      instance_types = list(string)
      capacity_type  = string

      scaling_config = object({
        desired_size = number
        max_size     = number
        min_size     = number
      })
    })
  )
}

variable "node_group_role_arn" {
  description = "role arn of nodes"
  type        = string
}

variable "eks_node_policies" {
  description = "node policies"
  type = list(string)
}


