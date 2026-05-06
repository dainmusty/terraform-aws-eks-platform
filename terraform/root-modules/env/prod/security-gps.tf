# Bastion SG
module "bastion_sg" {
  source = "../../../modules/security/bastion"
  vpc_id = module.vpc.vpc_id
  env    = "Dev"

  bastion_ingress_rules = [
    {
      description = "Allow traffic from the internet"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  bastion_egress_rules = [
    {
      description = "Allow all egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  bastion_sg_tags = {
    Name        = "bastion-sg"
    Environment = "Dev"
  }

}


# Private SG - Use this a private EKS SG 
module "cluster_sg" {
  source = "../../../modules/security/private-sg" # Remember to change name from private to cluster sg.
  vpc_id = module.vpc.vpc_id
  env    = "Dev"

  ingress_rules = [
    {
      description               = "Allow traffic from bastion"
      from_port                 = 22
      to_port                   = 22
      protocol                  = "tcp"
      source_security_group_ids = [module.bastion_sg.bastion_sg_id]
    },
    {
      description               = "Allow traffic from bastion"
      from_port                 = 443
      to_port                   = 443
      protocol                  = "tcp"
      source_security_group_ids = [module.bastion_sg.bastion_sg_id]
    }
  ]

  egress_rules = [
    {
      description = "Allow all egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  cluster_sg_tags = {
    Name        = "cluster-sg"
    Environment = "Dev"
  }

}


# Public SG - Use this a public EKS SG
module "node_sg" {
  source = "../../../modules/security/public-sg"
  vpc_id = module.vpc.vpc_id
  env    = "Dev"

  ingress_rules = [

    # Node-to-node traffic
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      self        = true
      description = "Allow all node-to-node traffic"
    },

    # Kubelet API from control plane
    {
      from_port       = 10250
      to_port         = 10250
      protocol        = "tcp"
      security_groups = [module.cluster_sg.cluster_sg_id]
      description     = "Allow kubelet API from control plane"
    },
    {
      description     = "Allow control plane to reach nodes"
      from_port       = 0
      to_port         = 65535
      protocol        = "tcp"
      security_groups = [module.cluster_sg.cluster_sg_id]
    }

  ]

  # allow node -> anywhere egress
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]


  node_sg_tags = {
    Name        = "node-sg"
    Environment = "Dev"
  }

}