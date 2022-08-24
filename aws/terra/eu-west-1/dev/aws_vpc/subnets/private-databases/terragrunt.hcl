include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
}

terraform {
  source = "tfr:///cloudposse/dynamic-subnets/aws//?version=2.0.3"
}

dependencies {
  paths = [
    "../../vpc",
    "../../subnets/common"
  ]
}

dependency "vpc" {
  config_path = "../../vpc"
}

dependency "subnets_common" {
  config_path = "../../subnets/common"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "subnet"
  attributes = ["database"]

  availability_zones          = ["${local.region.aws_region}a", "${local.region.aws_region}b"]
  vpc_id                      = dependency.vpc.outputs.vpc_id
  igw_id                      = [dependency.vpc.outputs.igw_id]
  ipv4_cidr_block             = ["${local.env.vpc_cidr_block_prefix}.220.0/23"]
  private_route_table_enabled = true
  public_subnets_enabled      = false
  nat_gateway_enabled         = false
  private_subnets_enabled     = true
  max_subnet_count            = 2 # as we have only two AZs, we need maximum 2 subnets for control plane
  private_subnets_additional_tags = {
    "Description" = "Dedicated private subnet for various AWS DB services (RDS, DocumentDB, etc.)"
  }
}