locals {
  caller          = data.aws_caller_identity.current.id
  service_account = "external-dns"
}

resource "aws_iam_policy" "AWSExternalDNSIAMPolicy" {
  name        = "AWSExternalDNSIAMPolicy"
  path        = "/"
  description = "AWSExternalDNSIAMPolicy"
  policy      = file("policies/AWSExternalDNSIAMPolicy.json")
}



module "iam_eks_role_external_dns" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "eks-external-dns-role"

  role_policy_arns = {
    policy = "${aws_iam_policy.AWSExternalDNSIAMPolicy.arn}"
  }

  oidc_providers = {
    one = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:${local.service_account}"]
    }
  }
  depends_on = [aws_iam_policy.AWSExternalDNSIAMPolicy]
}

resource "kubernetes_service_account" "external-dns" {

  metadata {
    name      = local.service_account
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = "${module.iam_eks_role_external_dns.iam_role_arn}"
    }
  }
}

resource "helm_release" "external-dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"
  version    = "1.14.5"

  values = [
    "${file("values/external-dns.yaml")}",
    <<EOT
      serviceAccount:
        create: false
        name: external-dns
    EOT
  ]
  atomic = true
}
# https://kubernetes-sigs.github.io/external-dns/ https://kubernetes-sigs.github.io/external-dns/
