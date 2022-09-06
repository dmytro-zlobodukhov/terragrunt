include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))

  user_data = file("./scripts/install-vpn.sh")

  amis = {
    "us-east-1" = {
      "ami_id"        = "ami-01dcdbd83c7e846ec"
      "ami_owner"     = "131827586825",
      "instance_size" = "t3.micro"
    },
    "us-east-2" = {
      "ami_id"        = "ami-08142824d0029d801"
      "ami_owner"     = "131827586825",
      "instance_size" = "t3.micro"
    },
    "eu-west-1" = {
      "ami_id"        = "ami-0535dfe71f7948013"
      "ami_owner"     = "131827586825",
      "instance_size" = "t3.micro"
    },
    "eu-west-2" = {
      "ami_id"        = "ami-0ff6b53b4a63a025c"
      "ami_owner"     = "131827586825",
      "instance_size" = "t3.micro"
    },
  }
}

terraform {
  source = "tfr:///cloudposse/ec2-instance/aws//?version=0.43.0"
}

dependencies {
  paths = [
    "../../aws_vpc/vpc",
    "../../aws_vpc/subnets/common",
    "../sg-bastion",
    "../bastion-ssh-key"
  ]
}

dependency "vpc" {
  config_path = "../../aws_vpc/vpc"
}

dependency "subnets_common" {
  config_path = "../../aws_vpc/subnets/common"
}

dependency "security_group_bastion" {
  config_path = "../sg-bastion"
}

dependency "bastion_ssh_key" {
  config_path = "../bastion-ssh-key"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "bastion-host"

  ami           = local.amis["${local.region.aws_region}"].ami_id
  ami_owner     = local.amis["${local.region.aws_region}"].ami_owner
  ssh_key_pair  = dependency.bastion_ssh_key.outputs.key_name
  instance_type = local.amis["${local.region.aws_region}"].instance_size

  vpc_id                      = dependency.vpc.outputs.vpc_id
  security_group_enabled      = false
  security_groups             = [dependency.security_group_bastion.outputs.id]
  subnet                      = dependency.subnets_common.outputs.public_subnet_ids[0]
  associate_public_ip_address = true
  assign_eip_address          = true

  ebs_optimized    = true
  root_volume_size = 15
  root_volume_type = "gp3"

  delete_on_termination   = true
  disable_api_termination = true
  monitoring              = true

  user_data_base64 = base64encode(local.user_data)

  // ssm_patch_manager_enabled       = true
  // ssm_patch_manager_s3_log_bucket = "${local.common.namespace}-${local.env.env_name}-${local.region.aws_region}-ssm-logs"


  // tags = merge(
  //   var.tags,
  //   {
  //     "Patch Group" = "bastion",
  //     "TOPATCH"     = "true",
  //     "TOSCAN"      = "true"
  //   }
  // )
}