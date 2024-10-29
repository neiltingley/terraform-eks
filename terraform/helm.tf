# resource "helm_release" "example" {
#   name       = "argo"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
  
#   values = [
#     "${file("argocd-values.yaml")}"
#   ]
# }