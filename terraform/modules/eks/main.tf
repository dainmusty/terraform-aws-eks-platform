# Create EKS Cluster
resource "aws_eks_cluster" "dev_cluster" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = var.cluster_role

  vpc_config {
    subnet_ids = var.subnet_ids
  }
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true    # Give admin permissions to the cluster creator
  }
  depends_on = [
    var.cluster_policy
  ]
}


# Lunch Template for EKS Managed Node Group
resource "aws_launch_template" "eks_nodes" {
  name = "eks-node-lt"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # include your instance type, AMI, SGs, etc.
}


# Create EKS Managed Node Group

resource "aws_eks_node_group" "eks_worker_node" {
  for_each = var.dev_ng

  cluster_name    = var.cluster_name
  node_group_name = each.key
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = var.subnet_ids

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    min_size     = each.value.scaling_config.min_size
    max_size     = each.value.scaling_config.max_size
   
  }

  depends_on = [
     aws_eks_cluster.dev_cluster,
    var.eks_node_policies
  ]
}


