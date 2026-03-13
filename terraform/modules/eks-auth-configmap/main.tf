# Build YAML-friendly mapRoles and mapUsers strings. The aws-auth ConfigMap expects YAML in these fields.
locals {
  # Convert each map_roles object to a YAML structure when encoded
  role_entries = [
    for r in var.map_roles : {
      rolearn  = r.rolearn
      username = r.username
      groups   = r.groups
    }
  ]

  user_entries = [
    for u in var.map_users : {
      userarn  = u.userarn
      username = u.username
      groups   = u.groups
    }
  ]
  # Use yamlencode to produce YAML text (kubernetes ConfigMap expects YAML string)
  map_roles_yaml = length(local.role_entries) > 0 ? yamlencode(local.role_entries) : ""
  map_users_yaml = length(local.user_entries) > 0 ? yamlencode(local.user_entries) : ""
}

# Configure an in-module kubernetes provider that authenticates via aws eks get-token with role-arn
provider "kubernetes" {
  host = var.cluster_details.endpoint

  cluster_ca_certificate = base64decode(var.cluster_details.certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = [
      "eks",
      "get-token",
      "--cluster-name",
      var.cluster_name,
      "--role-arn",
      var.bootstrap_role_arn
    ]
  }
}

# Create or update aws-auth ConfigMap in kube-system
resource "kubernetes_config_map_v1" "aws_auth" {
  count = var.enable_aws_auth_bootstrap ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    # Provide empty strings if none to avoid nulls
    mapRoles = local.map_roles_yaml
    mapUsers = local.map_users_yaml
  }

  lifecycle {
    create_before_destroy = false
    prevent_destroy      = true
  }

  # Ensure cluster exists before we attempt to apply
  depends_on = [var.cluster_name]
}

# will explore this option later.