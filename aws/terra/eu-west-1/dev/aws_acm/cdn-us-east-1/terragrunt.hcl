include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
}

terraform {
  source = "tfr:///cloudposse/acm-request-certificate/aws//?version=0.16.2"
}

dependencies {
  paths = [
    "../../aws_route53/external"
  ]
}

inputs = {
  domain_name                       = local.env.dns_parent_zone_name # Hosted Zone must exist in Route53
  process_domain_validation_options = true
  ttl                               = "300"
  subject_alternative_names = [
    "*.${local.env.dns_parent_zone_name}",
    "*.apps.${local.env.dns_parent_zone_name}"
  ]
}

generate "provider" {
  path      = "_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region                   = "${local.region.aws_acm_cloudfront_region}"
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