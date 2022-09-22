include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
}

terraform {
  source = "tfr:///cloudposse/cloudfront-s3-cdn/aws//?version=0.82.5"
}

dependencies {
  paths = [
    "../../aws_route53/external",
    "../../aws_acm/cdn-us-east-1"
  ]
}

dependency "acm" {
  config_path = "../../aws_acm/cdn-us-east-1"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "s3-cdn"
  attributes  = ["${basename(get_terragrunt_dir())}"]

  parent_zone_name    = "${local.env.dns_parent_zone_name}"
  aliases             = ["cdn-1.${local.env.dns_parent_zone_name}", "app-1.${local.env.dns_parent_zone_name}"]
  dns_alias_enabled   = true
  acm_certificate_arn = dependency.acm.outputs.arn

  minimum_protocol_version  = "TLSv1.2_2021"
  viewer_protocol_policy    = "https-only"
  origin_ssl_protocols      = ["TLSv1.2"]
  geo_restriction_locations = ["VE", "KP", "IR", "CU", "SY"]
  geo_restriction_type      = "blacklist"
}