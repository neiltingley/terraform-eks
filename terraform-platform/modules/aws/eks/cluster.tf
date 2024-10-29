# data "tls_certificate" "demo" {
#   url = aws_eks_cluster.demo.identity.0.oidc.0.issuer
# }
# data "aws_eks_cluster" "demo" {
#   name = aws_eks_cluster.demo.name
# }
# resource "aws_iam_openid_connect_provider" "demo" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.demo.certificates[0].sha1_fingerprint]
#   url             = aws_eks_cluster.demo.identity.0.oidc.0.issuer

# }
# data "aws_iam_policy_document" "example_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"
#     condition {
#       test     = "StringEquals"
#       variable = "${replace(aws_iam_openid_connect_provider.demo.url, "https://", "")}:sub"
#       values   = ["system:serviceaccount:kube-system:aws-node"]
#     }
#     principals {
#       identifiers = [aws_iam_openid_connect_provider.demo.arn]
#       type        = "Federated"
#     }
#   }
# }
# resource "aws_iam_role" "aws-node" {
#   assume_role_policy = data.aws_iam_policy_document.example_assume_role_policy.json
#   name               = "aws-node"
# }
# resource "aws_eks_identity_provider_config" "demo" {
#   cluster_name = var.cluster-name
#   oidc {
#     client_id                     = substr(aws_eks_cluster.demo.identity.0.oidc.0.issuer, -32, -1)
#     identity_provider_config_name = "sdemonew"
#     issuer_url                    = "https://${aws_iam_openid_connect_provider.demo.url}"

#   }
# }
