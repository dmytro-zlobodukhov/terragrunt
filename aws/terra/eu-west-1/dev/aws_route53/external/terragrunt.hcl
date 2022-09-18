include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
}

terraform {
  source = "tfr:///terraform-aws-modules/route53/aws//modules/zones?version=2.9.0"
}

inputs = {
  zones = {
    "${local.env.dns_parent_zone_name}" = {
      comment = "${local.env.dns_parent_zone_name} (production)"
    }
  }
}