module "eks" {
  source = "../../../modules/eks"

  # cluster variables
  cluster_name              = "effulgencetech"
  cluster_version           = "1.34"
  cluster_role              = module.iam_core.cluster_role_arn
  subnet_ids                = module.vpc.private_subnet_ids
  

  cluster_policy = [
    module.iam_core.cluster_policies
  ]

  # node group variables
  node_group_role_arn = module.iam_core.node_group_role_arn
  eks_node_policies   = module.iam_core.eks_node_policies
  dev_ng = {
    worker_nodes_config = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      scaling_config = {
        desired_size = 2
        max_size     = 3
        min_size     = 2
      }
    }

  }
}
