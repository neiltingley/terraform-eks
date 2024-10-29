

# module "iam_eks_role" {
#   source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   role_name = "AmazonEBSCSIDriverRole"

#   role_policy_arns = {
#     policy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
#   }

#   oidc_providers = {
#     one = {
#       provider_arn               = "${module.eks.oidc_provider_arn}"
#       namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
#     }
  
#   }
# }