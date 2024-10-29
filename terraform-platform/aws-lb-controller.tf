
# locals {
#     caller = data.aws_caller_identity.current.id
# }

# resource "aws_iam_policy" "WSLoadBalancerControllerIAMPolicy" {
#   name        = "WSLoadBalancerControllerIAMPolicy"
#   path        = "/"
#   description = "WSLoadBalancerControllerIAMPolicy"

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = file("policies/WSLoadBalancerControllerIAMPolicy.json")

# }

# module "iam_eks_role" {
#   source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   role_name = "aws-load-balancer-controller"
  
#   role_policy_arns = {
#     policy = "arn:aws:iam::${local.caller}:policy/WSLoadBalancerControllerIAMPolicy"
#   }

#   oidc_providers = {
#     one = {
#       provider_arn       =    module.eks.oidc_provider_arn
#       namespace_service_accounts = [ "default: aws-load-balancer-controller" ]
#     }
#     }
#     depends_on = [ aws_iam_policy.WSLoadBalancerControllerIAMPolicy ]
# }



# # eksctl create iamserviceaccount \
# #   --cluster eksworkshop-eksctl \
# #   --namespace kube-system \
# #   --name aws-load-balancer-controller \
# #   --attach-policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
# #   --override-existing-serviceaccounts \
# #   --approve