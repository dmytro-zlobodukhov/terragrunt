include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))

  kubernetes_version = "1.23"

  additional_iam_users    = []
  additional_iam_roles    = []
  additional_aws_accounts = []

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  addons = [
    {
      addon_name               = "kube-proxy"
      addon_version            = "v1.23.7-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = ""
    },
    {
      addon_name               = "vpc-cni"
      addon_version            = "v1.10.4-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = ""
    },
    {
      addon_name               = "coredns"
      addon_version            = "v1.8.7-eksbuild.2"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = ""
    },
    {
      addon_name               = "aws-ebs-csi-driver"
      addon_version            = "v1.10.0-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = ""
    }
  ]
}

terraform {
  source = "tfr:///cloudposse/eks-cluster/aws//?version=2.4.0"
}

dependencies {
  paths = [
    "../../aws_vpc/vpc",
    "../../aws_vpc/subnets/eks-control-plane",
    "../../aws_ec2/sg-bastion",
  ]
}

dependency "vpc" {
  config_path = "../../aws_vpc/vpc"
}

dependency "subnets_eks_control_plane" {
  config_path = "../../aws_vpc/subnets/eks-control-plane"
}

dependency "security_group_bastion" {
  config_path = "../../aws_ec2/sg-bastion"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "eks"

  region                     = local.region.aws_region
  vpc_id                     = dependency.vpc.outputs.vpc_id
  subnet_ids                 = dependency.subnets_eks_control_plane.outputs.private_subnet_ids
  allowed_security_group_ids = [dependency.security_group_bastion.outputs.id]
  // allowed_cidr_blocks        = [
  //   dependency.vpc.outputs.vpc_cidr_block
  // ]
  // custom_ingress_rules       = [
  //   {
  //     description              = "Allow access from Bastion host"
  //     protocol                 = "tcp"
  //     from_port                = 443
  //     to_port                  = 443
  //     type                     = "ingress"
  //     source_security_group_id = dependency.security_group_bastion.outputs.id
  //   }
  // ]

  kubernetes_version                = local.kubernetes_version
  cluster_encryption_config_enabled = false
  endpoint_private_access           = true
  endpoint_public_access            = false
  oidc_provider_enabled             = true
  create_eks_service_role           = true

  enabled_cluster_log_types    = local.enabled_cluster_log_types
  cluster_log_retention_period = 365

  apply_config_map_aws_auth   = false
  map_additional_iam_users    = local.additional_iam_users
  map_additional_iam_roles    = local.additional_iam_roles
  map_additional_aws_accounts = local.additional_aws_accounts

  addons = local.addons

  tags = {
    "Description" = "AWS EKS Cluster for ${upper(local.env.env_name)} environment"
  }
}