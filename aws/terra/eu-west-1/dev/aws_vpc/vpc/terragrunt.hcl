include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
}

terraform {
  source = "tfr:///cloudposse/vpc/aws//?version=1.1.1"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "vpc"

  ipv4_primary_cidr_block          = "${local.env.vpc_cidr_block_prefix}.${local.env.vpc_cidr_block_suffix}"
  assign_generated_ipv6_cidr_block = false
}