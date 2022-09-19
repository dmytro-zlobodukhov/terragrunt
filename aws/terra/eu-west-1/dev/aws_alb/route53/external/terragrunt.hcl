include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
}

terraform {
  source = "tfr:///cloudposse/route53-alias/aws//?version=0.13.0"
}

dependencies {
  paths = [
    "../../alb/external",
    "../../../aws_route53/external"
  ]
}

dependency "alb" {
  config_path = "../../alb/external"
}

dependency "route53" {
  config_path = "../../../aws_route53/external"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "alb"
  attributes  = ["external"]

  aliases         = ["*.${local.env.dns_parent_zone_name}"]
  parent_zone_id  = dependency.route53.outputs.route53_zone_zone_id["${local.env.dns_parent_zone_name}"]
  target_dns_name = dependency.alb.outputs.alb_dns_name
  target_zone_id  = dependency.alb.outputs.alb_zone_id
}