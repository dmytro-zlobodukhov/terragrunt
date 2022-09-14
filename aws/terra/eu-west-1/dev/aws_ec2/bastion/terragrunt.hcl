include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))

  user_data = file("./scripts/install-vpn-oracle.sh")
}

terraform {
  source = "tfr:///cloudposse/ec2-instance/aws//?version=0.43.0"
}

dependencies {
  paths = [
    "../../aws_vpc/vpc",
    "../../aws_vpc/subnets/common",
    "../sg-bastion",
    "../bastion-ssh-key",
    "../ami-finder/oracle-linux-8"
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

dependency "ami_finder" {
  config_path = "../ami-finder/oracle-linux-8"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "bastion-host"

  ami           = dependency.ami_finder.outputs.image_id
  ami_owner     = dependency.ami_finder.outputs.owner_id
  ssh_key_pair  = dependency.bastion_ssh_key.outputs.key_name
  instance_type = "${local.env.ec2_bastion_instance_type}"

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

  ssm_patch_manager_enabled = true # This setting will add "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" policy to the Instance Role
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