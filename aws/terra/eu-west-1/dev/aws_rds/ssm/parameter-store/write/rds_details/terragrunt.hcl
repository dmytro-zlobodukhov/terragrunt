include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))

  ssm_parameter_store_rds_details_prefifx = "/${local.common.namespace}/${local.env.env_name}/${local.region.aws_region}/rds/postgres"
}

terraform {
  source = "tfr:///cloudposse/ssm-parameter-store/aws//?version=0.10.0"
}

dependencies {
  paths = [
    "../../../../rds"
  ]
}

dependency "rds" {
  config_path = "../../../../rds"
}

inputs = {
  // namespace   = "${local.common.namespace}"
  // stage       = "${local.region.aws_region}"
  // environment = "${local.env.env_name}"
  // name        = "rds-master-password"

  parameter_write = [
    {
      name        = "${local.ssm_parameter_store_rds_details_prefifx}/master_username"
      value       = "dbadmin"
      type        = "String"
      overwrite   = "true"
      description = "Production database master_username"
    },
    {
      name        = "${local.ssm_parameter_store_rds_details_prefifx}/db_port"
      value       = "5432"
      type        = "String"
      overwrite   = "true"
      description = "Production database host URL"
    },
    {
      name        = "${local.ssm_parameter_store_rds_details_prefifx}/db_hostname"
      value       = dependency.rds.outputs.hostname
      type        = "String"
      overwrite   = "true"
      description = "Production database port"
    },
    {
      name        = "${local.ssm_parameter_store_rds_details_prefifx}/db_instance_address"
      value       = dependency.rds.outputs.instance_address
      type        = "String"
      overwrite   = "true"
      description = "Production database port"
    },
    {
      name        = "${local.ssm_parameter_store_rds_details_prefifx}/db_instance_endpoint"
      value       = dependency.rds.outputs.instance_endpoint
      type        = "String"
      overwrite   = "true"
      description = "Production database port"
    },
    {
      name        = "${local.ssm_parameter_store_rds_details_prefifx}/db_instance_arn"
      value       = dependency.rds.outputs.instance_arn
      type        = "String"
      overwrite   = "true"
      description = "Production database port"
    }
  ]
}