

locals {
  tags = {

    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.27.0"

  cluster_name                             = var.cluster_name
  cluster_version                          = "1.31"
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
  create_node_security_group               = true
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy = {
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = module.iam_eks_role.iam_role_arn
    }

  }

  enable_irsa              = true
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets
  authentication_mode      = "API_AND_CONFIG_MAP"
  create_iam_role          = true


  eks_managed_node_groups = {
    karpenter = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      taints = {
        # This Taint aims to keep just EKS Addons and Karpenter running on this MNG
        # The pods that do not tolerate this taint should run on nodes created by Karpenter
        addons = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        },
      }
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





data "aws_availability_zones" "available" {}
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia

}

resource "kubectl_manifest" "storage-class" {
  provider   = kubectl
  yaml_body  = file("extras/sc.yaml")
  depends_on = [module.eks]
}


