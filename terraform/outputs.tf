output "OIDC_provider" {
    value = module.eks.oidc_provider
    description = "EKS access list"
}

output "OIDC_issuer_url" {
    value = module.eks.cluster_oidc_issuer_url
    description = "EKS access list"
}

