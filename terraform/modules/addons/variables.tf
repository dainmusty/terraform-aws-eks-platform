# Variables for EKS Addons Module
# Cluster required addons variables (core-dns, kube-proxy, vpc-cni))
variable "cluster_version" {
  description = "Version of the EKS cluster"
  type        = string
}

variable "cluster_addons" {
  description = "Map of EKS addons and their configuration"
  type = map(object({
    most_recent                = optional(bool)
    addon_version              = optional(string)
    resolve_conflicts_on_update = optional(string)
  }))
}

variable "vpc_cni_irsa_role_arn" {
  description = "ARN of the VPC CNI IRSA role"
  type        = string
  
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  
}

# Alb Controller variables
variable "alb_controller_role_arn" {
  description = "ARN of the ALB controller role"
  type        = string
}


# ArgoCD variables
variable "argocd_role_arn" {
  description = "ARN of the ArgoCD role"
  type        = string
  
}

variable "argocd_hostname" {
  description = "Hostname for ArgoCD"
  type        = string
  
}

# Grafana variables
variable "grafana_secret_name" {
  description = "Name of the Grafana secret"
  type        = string
}

variable "grafana_irsa_arn" {
  description = "ARN of the IAM role for Grafana IRSA"
  type        = string
  
}

variable "prometheus_stack_version" {
  description = "prometheus stack version"
  type = string
} 


# Slack Webhook for Alertmanager variable
variable "slack_webhook_secret_name" {
  description = "Name of the Slack Webhook secret"
  type        = string
  default     = "slack-webhook-alertmanager"
}

# Ebs variables
variable "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI driver IAM role"
  type        = string
  
}


# Variables for providers
variable "cluster_endpoint" {
  description = "Cluster Endpoint"
  type = string
}

variable "cluster_certificate_authority_data" {
  description = "Cluster Certificate Authority"
  type = string
}


variable "terraform_role_arn" {
  description = "ARN of the Terraform admin role"
  type        = string
}

