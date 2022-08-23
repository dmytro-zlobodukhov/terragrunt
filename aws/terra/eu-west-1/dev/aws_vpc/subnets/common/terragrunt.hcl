include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("../common.json")))
}

terraform {
  source = "tfr:///cloudposse/dynamic-subnets/aws//?version=2.0.3"
}

dependencies {
  paths = [
    "../../vpc"
  ]
}

dependency "vpc" {
  config_path = "../../vpc"
}

inputs = {
  namespace              = "${local.common.namespace}"
  stage                  = "${local.region.aws_region}"
  environment            = "${local.env.env_name}"
  name                   = "subnet"

  vpc_id                 = dependency.vpc.outputs.vpc_id
  igw_id                 = [dependency.vpc.outputs.igw_id]
  ipv4_cidr_block        = ["${local.common.vpc_cidr_block_prefix}.0.0/17"]
  availability_zones     = ["${local.region.aws_region}a", "${local.region.aws_region}b"]

  nat_gateway_enabled    = true
  max_nats               = 1
  public_subnets_enabled = true
}