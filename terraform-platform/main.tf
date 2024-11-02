

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.27.0"

  cluster_name                             = var.cluster_name
  cluster_version                          = "1.31"
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
 
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    aws-ebs-csi-driver     = {
      service_account_role_arn = module.iam_eks_role.iam_role_arn
    }
  }
  
  enable_irsa              = true
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets
  authentication_mode      = "API_AND_CONFIG_MAP"
  
    
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
module "eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "20.27.0"
  name            = "separate-eks-mng"
  cluster_name    = var.cluster_name
  cluster_version = "1.31"

  subnet_ids = module.vpc.private_subnets
  cluster_service_cidr = module.eks.cluster_service_cidr
  vpc_security_group_ids            = [module.eks.node_security_group_id]

  min_size     = 3
  max_size     = 21
  desired_size = 5

  instance_types = ["t3.small"]
  capacity_type  = "SPOT"

  labels = {
    Environment = "test"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  taints = {
  #   dedicated = {
  #     key    = "dedicated"
  #     value  = "gpuGroup"
  #     effect = "NO_SCHEDULE"
  #   }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
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

resource "aws_iam_policy" "EKSClusterAutoscalerPolicy" {
  name        = "EKSClusterAutoscalerolicy"
  path        = "/"
  description = "EKSClusterAutoscalerPolicy"
  policy = file("policies/EKSClusterAutoscalerRole.json")
  
}
module "iam_eks_autoscaler_role" {
  
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "AmazonEKSAutoscalerRole"

  role_policy_arns = {
    policy = aws_iam_policy.EKSClusterAutoscalerPolicy.arn
  }

  oidc_providers = {
    one = {
      provider_arn               = "${module.eks.oidc_provider_arn}"
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.27.0"
  cluster_name = var.cluster_name

  create_node_iam_role = false
  node_iam_role_arn    = module.eks_managed_node_group.iam_role_arn

  # Since the node group role will already have an access entry
  create_access_entry = false

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "kubectl_manifest" "storage-class" {
  
  yaml_body = file("extras/sc.yaml")
  
}