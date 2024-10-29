# module "eks" {
#   source = "./modules/aws/eks"

#   region          = var.region
#   cluster_name    = var.cluster_name
#   private_subnets = module.vpc.private_subnets
#   public_subnets  = module.vpc.public_subnets
#   vpc_id          = module.vpc.vpc_id

#   managed_node_groups = {
#     demo_group = {
#       name           = "demo-node-group"
#       desired_size   = 3
#       min_size       = 1
#       max_size       = 5
#       instance_types = ["t3a.small"]
#     }
#   }
# }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                             = var.cluster_name
  cluster_version                          = "1.31"
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
 
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    aws-ebs-csi-driver     = {}

  }
  enable_irsa              = true
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets
  authentication_mode      = "API_AND_CONFIG_MAP"

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3a.small"]
    type           = "spot"
  }

  eks_managed_node_groups = {
    demo_group = {
      name           = "general"
      desired_size   = 3
      min_size       = 1
      max_size       = 5
      instance_types = ["t3a.small"]
      type           = "spot"
    }
  }


  access_entries = {
    # One access entry with a policy associated
    thump = {
      kubernetes_groups = ["cluster-admin"]
      principal_arn     = "arn:aws:iam::728277589254:user/thump-admin"

      policy_associations = {
        cluster = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

# resource "kubernetes_config_map" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = yamlencode([
#       {
#         rolearn  = module.eks.eks_admins_role.arn
#         username = module.eks.eks_admins_role.name
#         groups   = ["system:masters"]
#       },
#       {
#         rolearn  = module.eks.eks_admins_role.arn
#         username = "system:node:{{EC2PrivateDNSName}}"
#         groups   = ["system:bootstrappers", "system:nodes"]
#       }
#     ])
#     mapUsers = yamlencode([
#       {
#         userarn  = data.aws_caller_identity.current.arn
#         username = split("/", data.aws_caller_identity.current.arn)[1]
#         groups   = ["system:masters"]
#       },
#       { 
#         userarn = "arn:aws:iam::728277589254:user/thump-admin"
#         username = split("/", data.aws_caller_identity.current.arn)[1]
#         groups   = ["system:masters"]

#       }
#     ])
#   }

# }


resource "null_resource" "kubectl" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${var.cluster_name}"
  }
  depends_on = [module.eks]
}

# mapUsers = yamlencode([
#       {
#         userarn  = data.aws_caller_identity.current.arn
#         username = split("/", data.aws_caller_identity.current.arn)[1]
#         groups   = ["system:masters"]
#       },
#       { 

#         username = split("/", data.aws_caller_identity.current.arn)[1]
#         groups   = ["system:masters"]

#       }

#   tags = {
#     Environment = "dev"
#     Terraform   = "true"
#   }
# }
