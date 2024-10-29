resource "helm_release" "example" {
  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argo"
  
  values = [
    "${file("argocd-values.yaml")}"
  ]
}