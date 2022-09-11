include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))

  sg_ingress_ssh_alowed_cidrs = [
    "0.0.0.0/0" # fix this parameter to allow just necessary list of IP addresses to access SSH over the internet
  ]
}

terraform {
  source = "tfr:///cloudposse/security-group/aws//?version=1.0.1"
}

dependencies {
  paths = [
    "../../aws_vpc/vpc",
    "../../aws_vpc/subnets/common"
  ]
}

dependency "vpc" {
  config_path = "../../aws_vpc/vpc"
}

dependency "subnets_common" {
  config_path = "../../aws_vpc/subnets/common"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "bastion-sg"

  allow_all_egress = true

  rules = [
    // {
    //   key         = "ssh"
    //   type        = "ingress"
    //   from_port   = 22
    //   to_port     = 22
    //   protocol    = "tcp"
    //   cidr_blocks = local.sg_ingress_ssh_alowed_cidrs
    //   self        = null
    //   description = "Allow SSH access from allowed CIDR block"
    // },
    {
      key         = "HTTP"
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      self        = null
      description = "Allow HTTP access from allowed CIDR block"
    },
    {
      key         = "HTTPS"
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      self        = null
      description = "Allow HTTPS access from allowed CIDR block"
    },
    {
      key         = "OVPN"
      type        = "ingress"
      from_port   = 13548
      to_port     = 13548
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      self        = null
      description = "Allow OpenVPN access from anywhere"
    },
    {
      key         = "OVPN-SRV"
      type        = "ingress"
      from_port   = 13549
      to_port     = 13549
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      self        = null
      description = "Allow OpenVPN access (service accounts) from anywhere"
    },
    {
      key         = "WG"
      type        = "ingress"
      from_port   = 23548
      to_port     = 23548
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      self        = null
      description = "Allow WireGuard access from anywhere"
    }
  ]

  vpc_id = dependency.vpc.outputs.vpc_id

  tags = {
    "Description" = "Dedicated security group for EC2 Bastion Host"
  }
}