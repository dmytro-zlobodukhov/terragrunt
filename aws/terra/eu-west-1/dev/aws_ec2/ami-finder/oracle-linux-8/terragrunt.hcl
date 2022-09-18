include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
}

terraform {
  source = "git::git@github.com:dmytro-zlobodukhov/terraform-modules.git//tg-helpers/ami-finder/?ref=main"
}

inputs = {
  most_recent = true
  owners      = ["131827586825"]
  filter = [
    {
      name   = "name"
      values = ["OL8.5-x86_64-HVM-2021-11-24"]
    }
  ]
}