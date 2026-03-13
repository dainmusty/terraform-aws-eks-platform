output "config_map_name" {
  description = "aws-auth ConfigMap name (if created)"
  value = (
    length(kubernetes_config_map_v1.aws_auth) > 0
    ? kubernetes_config_map_v1.aws_auth[0].metadata[0].name
    : null
  )
}

output "map_roles_yaml" {
  description = "Generated mapRoles YAML"
  value       = local.map_roles_yaml
}

output "map_users_yaml" {
  description = "Generated mapUsers YAML"
  value       = local.map_users_yaml
}
