

locals {
  aws_account_number = data.aws_caller_identity.current
}

module "vpc" {
  source = "./modules/aws/vpc"

  vpc_name             = "${var.cluster_name}-vpc"
  cidr_block           = "10.0.0.0/16"
  nat_gateway          = true
  enable_dns_support   = true
  enable_dns_hostnames = true
  cluster_name         = var.cluster_name

  public_subnet_count  = 3
  private_subnet_count = 3
  public_subnet_tags = {

    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
"karpenter.sh/discovery"                    = var.cluster_name    
    "name"                                      = "${var.cluster_name}-public"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
    "karpenter.sh/discovery"                    = var.cluster_name
    "name"                                      = "${var.cluster_name}-private"

  }
}
