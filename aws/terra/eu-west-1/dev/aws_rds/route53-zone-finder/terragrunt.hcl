include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
}

terraform {
  source = "git::git@github.com:dmytro-zlobodukhov/terraform-modules.git//tg-helpers/route53-zone-finder/?ref=main"
}

inputs = {
  zone_name = "test001.com" # Hosted Zone must exist in Route53
}