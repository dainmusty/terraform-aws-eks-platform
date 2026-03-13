variable "grafana_secret_name" {
  description = "Name of the secret containing Grafana admin credentials"
  type        = string 
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_auth" {
  description = "Name of the EKS cluster for authentication"
  type        = string
}

# OIDC Provider Variables
variable "oidc_provider_url" {
  description = "url of the OIDC provider"
  type        = string
}

variable "oidc_issuer" {
  description = "OIDC issuer URL (without https://)"
  type        = string
}



