

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
    aws-ebs-csi-driver     = {
     
      service_account_role_arn = module.iam_eks_role.iam_role_arn

    }

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



resource "null_resource" "kubectl" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${var.cluster_name}"
  }
  depends_on = [module.eks]
}


module "iam_eks_role" {
  
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "AmazonEBSCSIDriverRole"

  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  oidc_providers = {
    one = {
      provider_arn               = "${module.eks.oidc_provider_arn}"
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# resource "kubernetes_service_account" "ebs-csi-controller-sa" {
  
#   metadata {
#     name      = "ebs-csi-controller-sa"
#     namespace = "kube-system"
#     annotations = {
#       "eks.amazonaws.com/role-arn" = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
#     }
    
#   }
# }