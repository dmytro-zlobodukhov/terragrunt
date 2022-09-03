locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
  
  resources_prefix = "${local.common.namespace}-${local.env.env_name}-${local.region.aws_region}"
}

remote_state {
  backend      = "s3"
  disable_init = tobool(get_env("TERRAGRUNT_DISABLE_INIT", "false"))

  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = "${local.resources_prefix}-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    dynamodb_table = "${local.resources_prefix}-terraform-state-lock"
    encrypt        = true
    region         = "${local.region.aws_region}"
    profile        = "${local.common.aws_profile}"

    // skip_metadata_api_check     = true
    // skip_credentials_validation = true
  }
}

generate "provider" {
  path      = "_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region                   = "${local.region.aws_region}"
  shared_config_files      = ["$HOME/.aws/config"]
  shared_credentials_files = ["$HOME/.aws/credentials"]
  profile                  = "${local.common.aws_profile}"
  
  default_tags {
    tags = {
      Terraform = "true"
      Terragrunt = "true"
    }
  }
}
EOF
}