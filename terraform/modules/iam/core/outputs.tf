output "admin_role_arn" {
  description = "ARN of the admin role"
  value       = aws_iam_role.admin_role.arn
}

output "config_role_arn" {
  description = "ARN of the config role"
  value       = aws_iam_role.config_role.arn
}

output "permission_boundary_arn" {
  description = "ARN of the permission boundary policy"
  value       = aws_iam_policy.permission_boundary.arn
}

output "policy_attachment_status" {
  value = true
}

output "grafana_role_arn" {
  description = "ARN of the Grafana role"
  value       = aws_iam_role.grafana_role.arn
  
}

output "prometheus_role_arn" {
  description = "ARN of the Prometheus role"
  value       = aws_iam_role.prometheus_role.arn
}


output "prometheus_role_name" {
  description = "Name of the Prometheus iam role"
  value       = aws_iam_role.prometheus_role.name
}

output "grafana_role_name" {
  description = "Name of the Grafana iam role"
  value       = aws_iam_role.grafana_role.name
}

# output "grafana_instance_profile_name" {
#   description = "Name of the Grafana instance profile"
#   value       = aws_iam_instance_profile.grafana_instance_profile.name
# }

# output "prometheus_instance_profile_name" {
#   description = "Name of the Prometheus instance profile"
#   value       = aws_iam_instance_profile.prometheus_instance_profile.name
# }

# output "rbac_instance_profile_name" {
#   description = "Name of the rbac instance profile"
#   value       = aws_iam_instance_profile.rbac_instance_profile.name
# }



# Output for EKS Cluster & Node Group Roles, policies and attachments.
output "cluster_role_arn" {
  value = aws_iam_role.cluster_role.arn
}

output "node_group_role_arn" {
  value = aws_iam_role.node_group_role.arn
  
}

# For_each policy attachments → output as map
output "cluster_policies" {
  description = "Map of EKS cluster IAM policy attachments"
  value       = [
    for k, p in aws_iam_role_policy_attachment.eks_cluster_policies : p.policy_arn
  ]
}

# For_each policy attachments → output as map
output "eks_node_policies" {
  description = "List of policy ARNs attached to the EKS node role"
  value = [
    for k, p in aws_iam_role_policy_attachment.eks_node_policies :
    p.policy_arn
  ]
}


