
resource "aws_iam_policy" "WSLoadBalancerControllerIAMPolicy" {
  name        = "WSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "WSLoadBalancerControllerIAMPolicy"
  policy = file("policies/WSLoadBalancerControllerIAMPolicy.json")

}

module "iam_eks_role_lb" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "aws-load-balancer-controller"
  
  role_policy_arns = {
    policy = "arn:aws:iam::${local.caller}:policy/WSLoadBalancerControllerIAMPolicy"
  }

  oidc_providers = {
      one = {
        provider_arn       =    module.eks.oidc_provider_arn
        namespace_service_accounts = [ "kube-system:aws-load-balancer-controller" ]
      }
    }
    depends_on = [ aws_iam_policy.WSLoadBalancerControllerIAMPolicy ]
}

resource "kubernetes_service_account" "ebs-csi-controller-sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_eks_role_lb.iam_role_arn
    }
  }
}


resource "helm_release" "aws-lb-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version   = "1.9.2"
  values = ["${file("values/aws-lb-values.yaml")}"]
  atomic = true
  set {
    name  = "clusterName"
    value = var.cluster_name
  }

}