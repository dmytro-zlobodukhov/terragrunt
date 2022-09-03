include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))

  # VPC SUBNET SETTINGS
  ipv4_cidr_block_prefix = local.env.vpc_cidr_block_prefix
  ipv4_cidr_block_suffix = local.env.subnets["${basename(get_terragrunt_dir())}"].cidr_block_suffix
  ipv4_cidr_block        = "${local.ipv4_cidr_block_prefix}.${local.ipv4_cidr_block_suffix}"
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
  attributes  = ["${basename(get_terragrunt_dir())}"]

  vpc_id = dependency.vpc.outputs.vpc_id
  igw_id = [dependency.vpc.outputs.igw_id]

  ipv4_cidr_block             = ["${local.ipv4_cidr_block}"]
  private_route_table_enabled = local.env.subnets["${basename(get_terragrunt_dir())}"].private_route_table_enabled
  public_subnets_enabled      = local.env.subnets["${basename(get_terragrunt_dir())}"].public_subnets_enabled
  nat_gateway_enabled         = local.env.subnets["${basename(get_terragrunt_dir())}"].nat_gateway_enabled
  private_subnets_enabled     = local.env.subnets["${basename(get_terragrunt_dir())}"].private_subnets_enabled
  max_subnet_count            = local.env.subnets["${basename(get_terragrunt_dir())}"].max_subnet_count
  max_nats                    = local.env.subnets["${basename(get_terragrunt_dir())}"].max_nats

  public_subnets_additional_tags  = merge(local.env.subnets["${basename(get_terragrunt_dir())}"].public_subnets_additional_tags)
  private_subnets_additional_tags = merge(local.env.subnets["${basename(get_terragrunt_dir())}"].private_subnets_additional_tags)
}