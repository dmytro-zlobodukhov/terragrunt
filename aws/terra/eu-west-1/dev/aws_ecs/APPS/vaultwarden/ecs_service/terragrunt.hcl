include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
  app    = jsondecode(file(find_in_parent_folders("app.json")))

  ssm_parameter_store_rds_details_prefix = "/${local.common.namespace}/${local.env.env_name}/${local.region.aws_region}/rds/postgres"
  container_name_prefix                  = "${local.common.namespace}-${local.env.env_name}-${local.region.aws_region}"
  database_name                          = local.app.app_name
  app_name                               = local.app.app_name
  container_name                         = "${local.container_name_prefix}-${local.app_name}"
  container_image                        = "vaultwarden/server:latest"
}

terraform {
  source = "tfr:///cloudposse/ecs-web-app/aws//?version=1.3.0"
}

dependencies {
  paths = [
    "../../../../aws_vpc/vpc",
    "../../../../aws_vpc/subnets/common",
    "../../../../aws_ec2/sg-bastion",
    "../../../ecs_cluster",
    // "../ssm/parameter-store/read",
    "../../../../aws_alb/alb/external"
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

// dependency "ssm_rds_details" {
//   config_path = "../ssm/parameter-store/read"
// }

dependency "alb" {
  config_path = "../../../../aws_alb/alb/external"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = local.app.app_name

  container_name   = local.container_name
  container_image  = local.container_image
  desired_count    = 1
  container_cpu    = 256
  container_memory = 512
  container_port   = 80
  build_timeout    = 5

  region                 = local.region.aws_region
  vpc_id                 = dependency.vpc.outputs.vpc_id
  launch_type            = "FARGATE"
  use_alb_security_group = true

  capacity_provider_strategies = [
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 100
      base              = 1
    },
    // {
    //   capacity_provider = "FARGATE"
    //   weight            = 0
    //   base              = 0
    // }
  ]

  container_environment = [
    {
      name  = "LAUNCH_TYPE"
      value = "FARGATE"
    },
    {
      name  = "VPC_ID"
      value = dependency.vpc.outputs.vpc_id
    }
  ]

  codepipeline_enabled = false
  webhook_enabled      = false
  badge_enabled        = false
  ecs_alarms_enabled   = false
  autoscaling_enabled  = false

  aws_logs_region  = local.region.aws_region
  ecs_cluster_arn  = dependency.ecs_cluster.outputs.cluster_arn
  ecs_cluster_name = dependency.ecs_cluster.outputs.cluster_name
  // ecs_security_group_ids = [dependency.alb.outputs.security_group_id]
  ecs_private_subnet_ids = dependency.subnets_common.outputs.private_subnet_ids

  alb_security_group                              = dependency.alb.outputs.security_group_id
  alb_target_group_alarms_enabled                 = false
  alb_target_group_alarms_3xx_threshold           = 25
  alb_target_group_alarms_4xx_threshold           = 25
  alb_target_group_alarms_5xx_threshold           = 25
  alb_target_group_alarms_response_time_threshold = 0.5
  alb_target_group_alarms_period                  = 300
  alb_target_group_alarms_evaluation_periods      = 1

  alb_arn_suffix               = dependency.alb.outputs.alb_arn_suffix
  alb_container_name           = local.container_name
  alb_ingress_healthcheck_path = "/"

  # Without authentication, both HTTP and HTTPS endpoints are supported
  alb_ingress_unauthenticated_listener_arns       = dependency.alb.outputs.listener_arns
  alb_ingress_unauthenticated_listener_arns_count = 2

  # All paths are unauthenticated
  alb_ingress_unauthenticated_paths             = ["/*"]
  alb_ingress_listener_unauthenticated_priority = 100
  alb_ingress_healthcheck_path                  = "/alive"
}