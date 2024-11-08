




resource "helm_release" "argocd" {
  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  create_namespace = true
  namespace = "argocd"
  atomic = true
  values = [
    "${file("values/argocd.yaml")}"
  ]
}

resource "helm_release" "elastic-operator" {
  name       = "el"
  repository = "https://elastic https://helm.elastic.co"
  chart      = "elastic/eck-operator"
  create_namespace = true
  namespace = "elastic-system"
  atomic = true
  values = [
    "${file("values/eck-operator.yaml")}"
  ]
}

# Install an eck-managed Elasticsearch and Kibana using the default values, which deploys the quickstart examples.
#helm install es-kb-quickstart elastic/eck-stack -n elastic-stack --create-namespace

resource "helm_release" "eck-stack" {
  name       = "ecs-stack-quickstart"
  repository = "https://elastic https://helm.elastic.co"
  chart      = "elastic/eck-stack"
  namespace = "elastic-stack"
  create_namespace = true
  atomic = true
  values = [

    "${file("values/eck-stack.yaml")}"
  ]
 
  depends_on = [ helm_release.elastic-operator ]
}

# resource "helm_release" "eck-beats" {
#   name       = "ecs-stack-quickstart"
#   repository = "https://elastic https://helm.elastic.co"
#   chart      = "elastic/filebeat"
#   namespace = "elastic-system"
#   create_namespace = true
#   atomic = true
#   values = [

#     "${file("values/ecs-beats.yaml")}"
#   ]
 
#   depends_on = [ helm_release.elastic-operator ]
# }


resource "kubectl_manifest" "kibana-ingress" {
  provider   = kubectl
  yaml_body  = file("kibana.yaml")
  depends_on = [ helm_release.eck-stack]

}

#kubectl get secret elasticsearch-es-elastic-user -o go-template='{{.data.elastic | base64decode}}' -n elastic-stack