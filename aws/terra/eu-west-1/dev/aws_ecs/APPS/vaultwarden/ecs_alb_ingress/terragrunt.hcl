include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))

  ssm_parameter_store_rds_details_prefix = "/${local.common.namespace}/${local.env.env_name}/${local.region.aws_region}/rds/postgres"
  container_name_prefix                  = "${local.common.namespace}-${local.env.env_name}-${local.region.aws_region}"
  database_name                          = "vaultwarden"
  app_name                               = "vaultwarden"
  container_name                         = "${local.container_name_prefix}-vaultwarden"
  container_image                        = "vaultwarden/server:latest"
}

terraform {
  source = "tfr:///cloudposse/alb-ingress/aws//?version=0.25.1"
}

dependencies {
  paths = [
    "../../../../aws_vpc/vpc",
    "../../../../aws_vpc/subnets/common",
    "../../../../aws_ec2/sg-bastion",
    "../../../ecs_cluster",
    "../../../../aws_alb/alb/external",
    "../ecs_service"
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

dependency "ecs_service" {
  config_path = "../ecs_service"
}

dependency "alb" {
  config_path = "../../../../aws_alb/alb/external"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "${local.app_name}-ingress"

  vpc_id                        = dependency.vpc.outputs.vpc_id
  unauthenticated_priority      = 1
  unauthenticated_paths         = ["/*"]
  unauthenticated_hosts         = ["test.${local.env.dns_parent_zone_name}"]
  protocol_version              = "HTTP2"
  slow_start                    = 15
  default_target_group_enabled  = false
  target_group_arn              = dependency.ecs_service.outputs.alb_ingress_target_group_arn
  unauthenticated_listener_arns = dependency.alb.outputs.listener_arns
}