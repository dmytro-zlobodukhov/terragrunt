include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))

  aws_iam_policy_eks_alb_autoscaler = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeLaunchTemplateVersions",
                "autoscaling:UpdateAutoScalingGroup",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:DescribeTags",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeAutoScalingGroups"
            ],
            "Resource": "*"
        }
    ]
}
    EOF
}

terraform {
  source = "tfr:///cloudposse/eks-iam-role/aws//?version=1.1.0"
}

dependencies {
  paths = [
    "../../aws_vpc/vpc",
    "../../aws_vpc/subnets/common",
    "../../aws_ec2/sg-bastion",
    "../eks"
  ]
}

dependency "vpc" {
  config_path = "../../aws_vpc/vpc"
}

dependency "subnets_common" {
  config_path = "../../aws_vpc/subnets/common"
}

dependency "security_group_bastion" {
  config_path = "../../aws_ec2/sg-bastion"
}

dependency "eks" {
  config_path = "../eks"
}

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "eks-cluster"

  aws_account_number          = get_aws_account_id()
  eks_cluster_oidc_issuer_url = dependency.eks.outputs.eks_cluster_identity_oidc_issuer
  service_account_name        = "autoscaler"
  service_account_namespace   = "kube-system"
  aws_iam_policy_document = [
    local.aws_iam_policy_eks_alb_autoscaler
  ]

  tags = {
    "Description" = "Dedicated AWS IAM Role for autoscaling ALB"
  }
}