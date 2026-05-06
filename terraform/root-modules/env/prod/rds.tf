#  module "rds" {
# #   source = "../../modules/rds"
# #   identifier = "gnpc-dev-db"
# #   db_engine = "postgres"
# #   db_engine_version = "15.5" # check for the latest version
# #   instance_class = "db.t3.micro"
# #   allocated_storage = 10
# #   db_name = "mydb"
# #   username = module.ssm.db_access_parameter_value
# #   password = module.ssm.db_secret_parameter_value
# #   subnet_ids = module.vpc.vpc_private_subnets
# #   vpc_security_group_ids = [module.security_group.private_sg_id]
# #   db_subnet_group_name = "rds-subnet-group"
# #   multi_az = false
# #   storage_type = "gp2"
# #   backup_retention_period = 7
# #   skip_final_snapshot = true
# #   publicly_accessible = false
# #   env = "dev"
# #   db_tags = {
# #     Name        = "rds-instance"
# #     Environment = "Dev"
# #     Owner       = "Musty"
# #   }
# # }
