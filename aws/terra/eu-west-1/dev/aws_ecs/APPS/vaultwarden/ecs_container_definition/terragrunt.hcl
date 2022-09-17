include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
}

terraform {
  source = "tfr:///cloudposse/ecs-container-definition/aws//?version=0.58.1"
}

dependencies {
  paths = [
    "../../../../aws_vpc/vpc",
    "../../../../aws_vpc/subnets/common",
    "../../../../aws_ec2/sg-bastion",
    "../../../ecs_cluster"
  ]
}

dependency "vpc" {
  config_path = "../../../../aws_vpc/vpc"
}

dependency "subnets_common" {
  config_path = "../../../../aws_vpc/subnets/common"
}

dependency "security_group_bastion" {
  config_path = "../../../../aws_ec2/sg-bastion"
}

dependency "ecs_cluster" {
  config_path = "../../../ecs_cluster"
}

inputs = {
  // namespace   = "${local.common.namespace}"
  // stage       = "${local.region.aws_region}"
  // environment = "${local.env.env_name}"
  // name        = "vaultwarden"

  container_name  = "vaultwarden"
  container_image = "vaultwarden/server:latest"
}