# module "eks_access" {
#   source = "../../../modules/eks-access"

#   eks_access_principal_arn  = "arn:aws:iam::651706774390:role/microservices-project-dev-tf-role" # use data to hide account id later
#   eks_access_entry_policies = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#   node_access_policies      = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSWorkerNodePolicy"
#   console_user_access       = "arn:aws:iam::651706774390:user/musty"
#   cluster_name              = module.eks.cluster_name

# }