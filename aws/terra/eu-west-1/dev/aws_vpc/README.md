###This folder contains `Terragrunt` modules related to `AWS VPC`.  
[Back to the modules](../README.md)

You can find `terragrunt.hcl` file in each folder. Each file contains Terragrunt code and some variables and parameters.  

Most of the `vpc` and `subnets` parameter values located in `env.json` file.  

In the `vpc` folder you can find code related to the `AWS VPC` itself:
- `vpc` - will create `AWS VPC` with the CIDR `10.220.0.0/16` and the name `terra-dev-eu-west-1-vpc`.
- CIDR block consists of `prefix` - `10.220` and `suffix` - `0.0/16` variables.

In the `subnets` folder you can find pre-configured examples:
- `common` - by default Terragrunt will create 2 `public` and 2 `private` subnets with the netmask `/20`, NAT gateway, Internet Gateway, routing tables, routing table associations, etc. This subnet is intended to use for different shared resources, such as external/internal ELBs, NAT Gateways, ECS/EKS Nodes and Node Groups, Bastion hosts, etc.
- `databases` - will create 2 `private` subnets and routing table. This subnet is intended to use for different AWS Database solutions, such as RDS, Redshift, DocumentDB, etc.
- `eks-control-plane` - will create 2 private subnets and routing table. This subnet is intended to use for for AWS EKS Control Plane cluster.

Worth to mention:
1. You can create subnets with default pre-configured values or edit setting for your needs.
2. If you want to create additional subnets - just copy the folder with any of subnet, rename the folder (folder name will be added to the `Name` tag for subnets) and add additional subnet block in the `env.json` file.
3. If you want to create your own subnets, folder name and subnet name in the map in `env.json` file must be the same.