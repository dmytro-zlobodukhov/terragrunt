include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
}

terraform {
  source = "tfr:///cloudposse/security-group/aws//?version=1.0.1"
}

dependencies {
  paths = [
    "../../aws_vpc/vpc",
    "../../aws_vpc/subnets/common"
  ]
}

dependency "vpc" {
  config_path = "../../aws_vpc/vpc"
}

dependency "subnets_common" {
  config_path = "../../aws_vpc/subnets/common"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "self-service-sg"

  allow_all_egress = true

  rules = [
    {
      key         = "self"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      self        = true
      description = "Allow self access"
    }
  ]

  vpc_id = dependency.vpc.outputs.vpc_id

  tags = {
    "Description" = "Shared security group for the services, thar require self-service access enabled (such as AWS Glue)"
  }
}