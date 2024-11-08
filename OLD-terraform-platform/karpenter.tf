
module "karpenter" {
  source                          = "terraform-aws-modules/eks/aws//modules/karpenter"
  version                         = "20.27.0"
  cluster_name                    = var.cluster_name
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}



resource "helm_release" "karpenter" {
  timeout          = 300
  namespace        = "karpenter"
  create_namespace = true
  atomic           = true

  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.0.7"

  set {
    name  = "settings.clusterName"
    value = var.cluster_name
  }

  # set {
  #   name  = "settings.clusterEndpoint"
  #   value = module.eks.cluster_endpoint
  # }

  # set {
  #   name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
  #   value = module.karpenter.iam_role_arn
  # }

  # set {
  #   name  = "settings.defaultInstanceProfile"
  #   value = module.karpenter.instance_profile_name
  # }

  set {
    name  = "settings.interruptionQueueName"
    value = module.karpenter.queue_name

  }

  depends_on = [ module.eks ]
}

resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          requirements:
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand"]
            - key: karpenter.k8s.aws/instance-category
              operator: In
              values: ["c", "m", "r"]
            - key: karpenter.k8s.aws/instance-generation
              operator: Gt
              values: ["2"]
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          expireAfter: 720h # 30 * 24h = 720h
      limits:
        cpu: 1000
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 1m
  YAML
  depends_on = [ helm_release.karpenter ]
}


resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2
      amiSelectorTerms:
      - id: ami-0c1b3153de7dbfd72
      - id: ami-037c2d1d338de52be
      role: ${module.karpenter.iam_role_arn}
      securityGroupSelectorTerms:
      - tags:
          karpenter.sh/discovery: ${var.cluster_name}
      subnetSelectorTerms:
      - tags:
          kubernetes.io/cluster/demo-cluster: shared
  YAML
  depends_on = [ helm_release.karpenter ]
}