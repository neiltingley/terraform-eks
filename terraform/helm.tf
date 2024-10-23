data "helm_repository" "argocd" {
  name = "argocd"
  url  = "https://argoproj.github.io/argo-helm"
}

resource "helm_release" "example" {
  name       = "argocd"
  repository = data.helm_repository.argocd.metadata[0].name
  chart      = "argocd"
  namespace  = "argocd"
   values = [
    file("${path.module}/argocd-values.yaml")
  ]
}

