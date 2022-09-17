include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
}

terraform {
  source = "tfr:///cloudposse/rds-cloudwatch-sns-alarms/aws//?version=0.3.1"
}

dependencies {
  paths = [
    "../../rds"
  ]
}

dependency "rds" {
  config_path = "../../rds"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "rds-alarms"

  db_instance_id = dependency.rds.outputs.instance_id
}