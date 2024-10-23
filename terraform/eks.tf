module "eks" {
  source = "./modules/aws/eks"

  region          = var.region
  cluster_name    = var.cluster_name
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id

  managed_node_groups = {
    demo_group = {
      name           = "demo-node-group"
      desired_size   = 3
      min_size       = 1
      max_size       = 5
      instance_types = ["t3a.small"]
    }
  }
}