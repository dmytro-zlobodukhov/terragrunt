include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))

  ssm_parameter_store_rds_details_prefix = "/${local.common.namespace}/${local.env.env_name}/${local.region.aws_region}/rds/postgres"
}

terraform {
  source = "tfr:///cloudposse/ssm-parameter-store/aws//?version=0.10.0"
}

dependencies {
  paths = [
    "../../../../../../aws_rds/ssm/parameter-store/write/rds_password",
    "../../../../../../aws_rds/ssm/parameter-store/write/rds_details"
  ]
}

inputs = {
  // namespace   = "${local.common.namespace}"
  // stage       = "${local.region.aws_region}"
  // environment = "${local.env.env_name}"
  // name        = "rds-master-password"

  parameter_read = [
    "${local.ssm_parameter_store_rds_details_prefix}/master_username",
    "${local.ssm_parameter_store_rds_details_prefix}/master_password",
    "${local.ssm_parameter_store_rds_details_prefix}/db_instance_endpoint"
  ]
}