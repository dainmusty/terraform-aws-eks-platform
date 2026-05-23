# # EC2 Module
module "ec2" {
  source = "../../../modules/ec2"

  resource_prefix = "staging"
  ami_ids        = ["ami-08b5b3a93ed654d19", "ami-02a53b0d62d37a757", "ami-02e3d076cbd5c28fa", "ami-0c7af5fe939f2677f", "ami-04b4f1a9cf54c11d0"]
  ami_names      = ["AL2023", "AL2", "Windows", "RedHat", "ubuntu"]
  instance_types = ["t2.micro", "t2.micro", "t2.micro", "t2.micro", "t2.micro"]
  key_name       = module.ssm.key_name_parameter_value
  #instance_profile_name      = module.iam_core.rbac_instance_profile_name
  public_instance_count  = [0, 0, 0, 0, 0]
  private_instance_count = [0, 0, 0, 0, 0]


  tag_value_public_instances = [
    [
      {
        Name        = "bastion"
        Environment = "staging"
      },

    ],
    [], [], [], []
  ]

  tag_value_private_instances = [
    [],
    [
      {
        Name = "db1"
        Tier = "database"
      }
    ],
    [],
    [], []
  ]

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  public_sg_id       = module.bastion_sg.bastion_sg_id
  private_sg_id      = module.bastion_sg.bastion_sg_id
  volume_size        = 8
  volume_type        = "gp3"
}
