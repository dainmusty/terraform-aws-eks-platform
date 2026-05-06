module "app_ecr_repo" {
  source = "../../../modules/ecr"

  for_each = {
    web = "tankofm-web"
    app = "tankofm-app"
    db  = "tankofm-db"
  }

  repository_name = each.value


  image_tag_mutability = "MUTABLE"
  scan_on_push         = true

  tags = {
    Environment = "dev"
    Project     = "Push-To-ECR"
  }
}






