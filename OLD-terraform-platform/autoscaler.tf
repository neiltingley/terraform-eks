resource "aws_iam_policy" "EKSClusterAutoscalerPolicy" {
  name        = "EKSClusterAutoscalerolicy"
  path        = "/"
  description = "EKSClusterAutoscalerPolicy"
  policy      = file("policies/EKSClusterAutoscalerRole.json")

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