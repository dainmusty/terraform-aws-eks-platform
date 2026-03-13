# # Access for terraform role to EKS Cluster
# resource "aws_eks_access_entry" "terraform" {
#   cluster_name  = var.cluster_name
#   principal_arn = var.eks_access_principal_arn  #"arn:aws:iam::651706774390:role/microservices-project-dev-tf-role"
#   type          = "STANDARD"

#   depends_on = [
#     var.cluster_name
#   ]
# }

# resource "aws_eks_access_policy_association" "terraform_admin" {
#   cluster_name  = var.cluster_name
#   principal_arn = aws_eks_access_entry.terraform.principal_arn

#   policy_arn = var.eks_access_entry_policies #"arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

#   access_scope {
#     type = "cluster"
#   }

#   depends_on = [
#     var.cluster_name
#   ]
# }

# # Console Access to Cluster
# resource "aws_eks_access_entry" "console_user" {
#   cluster_name  = var.cluster_name
#   principal_arn = var.console_user_access  # "arn:aws:iam::651706774390:user/username"
#   type          = "STANDARD"
# }

# resource "aws_eks_access_policy_association" "console_user_admin" {
#   cluster_name  = var.cluster_name
#   principal_arn = aws_eks_access_entry.console_user.principal_arn
#   policy_arn   = var.eks_access_entry_policies   #"arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

#   access_scope {
#     type = "cluster"
#   }

#   depends_on = [
#     var.cluster_name
#   ]
# }


