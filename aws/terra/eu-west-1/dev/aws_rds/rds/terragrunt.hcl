include {
  path = find_in_parent_folders()
}

locals {
  env    = jsondecode(file(find_in_parent_folders("env.json")))
  region = jsondecode(file(find_in_parent_folders("region.json")))
  common = jsondecode(file(find_in_parent_folders("account.json")))
}

terraform {
  source = "tfr:///cloudposse/rds/aws//?version=0.38.8"
}

dependencies {
  paths = [
    "../../aws_vpc/vpc",
    "../../aws_vpc/subnets/databases",
    "../../aws_ec2/sg-bastion",
    "../route53-zone-finder",
    "../ssm/parameter-store/read/rds_password"
  ]
}

dependency "vpc" {
  config_path = "../../aws_vpc/vpc"
}

dependency "subnets_databases" {
  config_path = "../../aws_vpc/subnets/databases"
}

dependency "security_group_bastion" {
  config_path = "../../aws_ec2/sg-bastion"
}

dependency "route53_zone_finder" {
  config_path = "../route53-zone-finder"
}

dependency "parameter_store_fetcher" {
  config_path = "../ssm/parameter-store/read/rds_password"
}

// dependency "parameter_store_fetcher" {
//   config_path = "../ssm/parameter-store-fetcher"
// }

inputs = {
  namespace   = "${local.common.namespace}"
  stage       = "${local.region.aws_region}"
  environment = "${local.env.env_name}"
  name        = "rds-postgres"

  dns_zone_id        = dependency.route53_zone_finder.outputs.zone_id
  host_name          = "psql-db" # DNS name for the record in Route53
  security_group_ids = [dependency.security_group_bastion.outputs.id]
  // ca_cert_identifier          = "rds-ca-2019"
  // allowed_cidr_blocks         = ["XXX.XXX.XXX.XXX/32"] # allowed additional CIDRs
  database_name     = "initdb"
  database_user     = "dbadmin"
  database_password = "${dependency.parameter_store_fetcher.outputs.values[0]}"
  // database_password           = dependency.parameter_store_fetcher.outputs.value
  database_port         = 5432
  multi_az              = false
  storage_type          = "gp2"
  allocated_storage     = 5
  max_allocated_storage = 20
  storage_encrypted     = true
  engine                = "postgres"
  engine_version        = "14.3"
  major_engine_version  = "14"
  instance_class        = "db.t3.micro"
  db_parameter_group    = "postgres14"
  // option_group_name           = "psql-options"
  publicly_accessible = false
  subnet_ids          = dependency.subnets_databases.outputs.private_subnet_ids
  vpc_id              = dependency.vpc.outputs.vpc_id
  // snapshot_identifier         = "rds:production-2015-06-26-06-05"
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = false
  maintenance_window          = "Mon:03:00-Mon:04:00"
  skip_final_snapshot         = false
  copy_tags_to_snapshot       = true
  backup_retention_period     = 7
  backup_window               = "22:00-03:00"
}