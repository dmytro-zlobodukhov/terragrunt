include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
  app    = jsondecode(file(find_in_parent_folders("app.json")))

  ssm_parameter_store_rds_details_prefix = "/${local.common.namespace}/${local.env.env_name}/${local.region.aws_region}/rds/postgres"
  container_name_prefix                  = "${local.common.namespace}-${local.env.env_name}-${local.region.aws_region}"
  database_name                          = local.app.app_name
}

terraform {
  source = "tfr:///cloudposse/ecs-container-definition/aws//?version=0.58.1"
}

dependencies {
  paths = [
    "../../../../aws_vpc/vpc",
    "../../../../aws_vpc/subnets/common",
    "../../../../aws_ec2/sg-bastion",
    "../../../ecs_cluster",
    "../ssm/parameter-store/read"
  ]
}

dependency "vpc" {
  config_path = "../../../../aws_vpc/vpc"
}

dependency "subnets_common" {
  config_path = "../../../../aws_vpc/subnets/common"
}

dependency "security_group_bastion" {
  config_path = "../../../../aws_ec2/sg-bastion"
}

dependency "ecs_cluster" {
  config_path = "../../../ecs_cluster"
}

dependency "ssm_rds_details" {
  config_path = "../ssm/parameter-store/read"
}

inputs = {
  // namespace   = "${local.common.namespace}"
  // stage       = "${local.region.aws_region}"
  // environment = "${local.env.env_name}"
  // name        = "vaultwarden"

  container_name  = "${local.container_name_prefix}-${local.app.app_name}"
  container_image = "vaultwarden/server:latest"

  port_mappings = [
    {
      containerPort = 80
      hostPort      = 80
      protocol      = "TCP"
    }
  ]

  map_environment = {
    // More details regarding env variables here: https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
    "DATABASE_URL"           = "postgresql://${dependency.ssm_rds_details.outputs.map["${local.ssm_parameter_store_rds_details_prefix}/master_username"]}:${dependency.ssm_rds_details.outputs.map["${local.ssm_parameter_store_rds_details_prefix}/master_password"]}@${dependency.ssm_rds_details.outputs.map["${local.ssm_parameter_store_rds_details_prefix}/db_instance_endpoint"]}/${local.database_name}"
    "SIGNUPS_ALLOWED"        = true
    "INVITATIONS_ALLOWED"    = true
    "SHOW_PASSWORD_HINT"     = false
    "PASSWORD_HINTS_ALLOWED" = false
    // "DOMAIN"                 = "https://vw.domain.tld:8443"
    // "SMTP_HOST"              = "smtp.domain.tld"
    // "SMTP_FROM"              = "vaultwarden@domain.tld"
    // "SMTP_FROM_NAME"         = "Vaultwarden"
    // "SMTP_SECURITY"          = "starttls" # ("starttls", "force_tls", "off") Enable a secure connection. Default is "starttls" (Explicit - ports 587 or 25), "force_tls" (Implicit - port 465) or "off", no encryption (port 25)
    // "SMTP_PORT"              = 587        # Ports 587 (submission) and 25 (smtp) are standard without encryption and with encryption via STARTTLS (Explicit TLS). Port 465 is outdated and used with Implicit TLS.
    // "SMTP_USERNAME"          = "username"
    // "SMTP_PASSWORD"          = "password"
    // "SMTP_TIMEOUT"           = 15
    // "SMTP_AUTH_MECHANISM"    = "Plain" # Defaults for SSL is "Plain" and "Login" and nothing for Non-SSL connections. Possible values: ["Plain", "Login", "Xoauth2"]. Multiple options need to be separated by a comma ','.
  }

  // environment_files = [
  //   {
  //     value = "arn:aws:s3:::s3_bucket_name/envfile_01.env"
  //     type  = "s3"
  //   },
  //   {
  //     value = "arn:aws:s3:::s3_bucket_name/another_envfile.env"
  //     type  = "s3"
  //   }
  // ]
}