include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))

  ssm_parameter_store_rds_master_password = "/${local.common.namespace}/${local.env.env_name}/${local.region.aws_region}/rds/postgres/master_password"
  random_password                         = trim(trimspace(run_cmd("sh", "-c", "aws secretsmanager get-random-password --password-length 30 --exclude-punctuation --query 'RandomPassword'")), "\"")
}

terraform {
  source = "tfr:///cloudposse/ssm-parameter-store/aws//?version=0.10.0"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "rds-master-password"

  parameter_write = [
    {
      name        = local.ssm_parameter_store_rds_master_password
      value       = local.random_password
      type        = "SecureString"
      overwrite   = "true"
      description = "Production database master password"
    }
  ]
}