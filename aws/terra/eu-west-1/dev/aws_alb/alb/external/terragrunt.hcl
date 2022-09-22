include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
}

terraform {
  source = "tfr:///cloudposse/alb/aws//?version=1.5.0"
}

dependencies {
  paths = [
    "../../../aws_acm/regional",
    "../../../aws_vpc/vpc",
    "../../../aws_vpc/subnets/common",
    "../../sg/external"
  ]
}

dependency "acm" {
  config_path = "../../../aws_acm/regional"
}

dependency "vpc" {
  config_path = "../../../aws_vpc/vpc"
}

dependency "subnets_common" {
  config_path = "../../../aws_vpc/subnets/common"
}

dependency "alb_sg" {
  config_path = "../../sg/external"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "alb"
  attributes  = ["external"]

  vpc_id             = dependency.vpc.outputs.vpc_id
  security_group_ids = [dependency.alb_sg.outputs.id]
  subnet_ids         = dependency.subnets_common.outputs.public_subnet_ids
  internal           = false
  ip_address_type    = "ipv4"
  http_port          = 80
  http_redirect      = true
  https_enabled      = true
  https_port         = 443
  certificate_arn    = dependency.acm.outputs.arn

  alb_access_logs_s3_bucket_force_destroy         = true
  alb_access_logs_s3_bucket_force_destroy_enabled = true
}