module "ssm" {
  source                   = "../../../modules/ssm"
  db_access_parameter_name = "/db/access"
  db_secret_parameter_name = "/db/secure/access"
  key_path_parameter_name  = "/kp/path"
  key_name_parameter_name  = "/kp/name"
  grafana_admin_password   = "/grafana/admin/password"
}