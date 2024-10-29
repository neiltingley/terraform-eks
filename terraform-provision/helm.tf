resource "helm_release" "argocd" {
  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  
  
  values = [
    "${file("argocd-values.yaml")}"
  ]
}