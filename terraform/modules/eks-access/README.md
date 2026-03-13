
# # Node Group Access Entry
# resource "aws_eks_access_entry" "nodes" {
#   cluster_name  = var.cluster_name
#   principal_arn = var.node_group_role_arn
#   type          = "EC2_LINUX"

#   depends_on = [
#     aws_eks_cluster.dev_cluster
#   ]
# }
