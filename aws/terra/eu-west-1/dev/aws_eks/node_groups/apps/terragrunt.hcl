include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))

  node_group_min_size     = 0
  node_group_desired_size = 2
  node_group_max_size     = 5
  node_goup_capacity_type = "SPOT"
  node_group_instance_types = [
    "t3.medium"
  ]
  node_group_after_cluster_joining_userdata = [file("./scripts/eks-node-provisioner.sh")]
  node_group_node_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

terraform {
  source = "tfr:///cloudposse/eks-node-group/aws//?version=2.6.0"
}

dependencies {
  paths = [
    "../../../aws_vpc/vpc",
    "../../../aws_vpc/subnets/common",
    "../../../aws_ec2/sg-bastion",
    "../../eks"
  ]
}

dependency "vpc" {
  config_path = "../../../aws_vpc/vpc"
}

dependency "subnets_common" {
  config_path = "../../../aws_vpc/subnets/common"
}

dependency "security_group_bastion" {
  config_path = "../../../aws_ec2/sg-bastion"
}

dependency "eks" {
  config_path = "../../eks"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "node-group"
  attributes  = ["${basename(get_terragrunt_dir())}"]

  subnet_ids                     = dependency.subnets_common.outputs.private_subnet_ids
  min_size                       = local.node_group_min_size
  desired_size                   = local.node_group_desired_size
  max_size                       = local.node_group_max_size
  instance_types                 = local.node_group_instance_types
  capacity_type                  = local.node_goup_capacity_type
  cluster_name                   = dependency.eks.outputs.eks_cluster_id
  create_before_destroy          = true
  kubernetes_version             = [dependency.eks.outputs.eks_cluster_version]
  cluster_autoscaler_enabled     = true
  after_cluster_joining_userdata = local.node_group_after_cluster_joining_userdata
  node_role_policy_arns          = local.node_group_node_role_policy_arns

  tags = {
    "Description" = "Managed Node Group - ${upper(basename(get_terragrunt_dir()))} Workers"
  }
}