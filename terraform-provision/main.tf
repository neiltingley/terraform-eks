
data "aws_route53_zone" "devopsworksio" {
     name = "devopsworks.io"
 }


 resource "aws_route53_zone" "tools"{
  name = "tools.devopsworks.io"
  tags = {
    Environment = "dev"
  }
}

resource "aws_route53_record" "tools" {
  zone_id = data.aws_route53_zone.devopsworksio.id

  name    = "tools.devopsworks.io"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.tools.name_servers
}

# trunk-ignore(checkov/CKV2_AWS_19)
resource "aws_eip" "lb" {
   domain       = "vpc"
}

resource "aws_acm_certificate" "argo" {
  domain_name = "tools.devopsworks.io"
  validation_method = "DNS"
  subject_alternative_names = [
 
  "*.tools.devopsworks.io"
  ]

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Environment = "test"
  }
}

resource "aws_route53_record" "hello_cert_dns" {
  allow_overwrite = true
  name =  tolist(aws_acm_certificate.argo.domain_validation_options)[0].resource_record_name
  records = [tolist(aws_acm_certificate.argo.domain_validation_options)[0].resource_record_value]
  type = tolist(aws_acm_certificate.argo.domain_validation_options)[0].resource_record_type
  zone_id = aws_route53_zone.tools.id
  ttl = 60
}

resource "aws_acm_certificate_validation" "hello_cert_validate" {
  certificate_arn = aws_acm_certificate.argo.arn
  validation_record_fqdns = [aws_route53_record.hello_cert_dns.fqdn]
}

# resource "aws_route53_record" "validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.argo.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = aws_route53_zone.tools.id
#   depends_on = [ aws_acm_certificate.argo ]
# }

# resource "aws_acm_certificate_validation" "argo" {
#   certificate_arn         = aws_acm_certificate.argo.arn
#   validation_record_fqdns = [for record in aws_route53_record.validation: record.fqdn]
#   depends_on = [ aws_route53_record.validation ]
# }

resource "helm_release" "argocd" {
  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  create_namespace = true
  namespace = "argocd"
  values = [
    "${file("values/argocd-values.yaml")}"
  ]
}

resource "helm_release" "elastic-operator" {
  name       = "elastic-operator"
  repository = "https://elastic https://helm.elastic.co"
  chart      = "elastic/eck-operator"
  create_namespace = true
  namespace = "elastic-system"
  values = [
    "${file("values/eck-values.yaml")}"
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
  values = [
    "${file("values/ecs-stack-values.yaml")}"
  ]
  depends_on = [ helm_release.elastic-operator ]
}

resource "kubectl_manifest" "kibana-ingress" {
  provider   = kubectl
  yaml_body  = file("kibana.yaml")
  depends_on = [ helm_release.eck-stack]

}

