include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))

  resource_prefix = "${local.common.namespace}-${local.env.env_name}-${local.region.aws_region}"
}

terraform {
  source = "tfr:///terraform-aws-modules/ecs/aws//?version=4.1.1"
}

// dependencies {
//   paths = [
//     "../../aws_vpc/vpc",
//     "../../aws_vpc/subnets/common",
//     "../../aws_ec2/sg-bastion"
//   ]
// }

// dependency "vpc" {
//   config_path = "../../aws_vpc/vpc"
// }

// dependency "subnets_common" {
//   config_path = "../../aws_vpc/subnets/common"
// }

// dependency "security_group_bastion" {
//   config_path = "../../aws_ec2/sg-bastion"
// }

// dependency "parameter_store_fetcher" {
//   config_path = "../ssm/parameter-store-fetcher"
// }

inputs = {
  cluster_name = "${local.resource_prefix}-ecs-cluster-fargate"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 0
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }
}