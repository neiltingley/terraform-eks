data "aws_eks_cluster" "demo-cluster" {
  name = "demo-cluster"
}
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

resource "aws_eip" "lb" {

}



resource "aws_route53_record" "argo" {
  zone_id = aws_route53_zone.tools.id
  name    = "argo.tools.devopsworks.io"
  
  type    = "CNAME"
  ttl     = "30"
  records = [  ]
  
}



resource "aws_acm_certificate" "argo" {
  domain_name = aws_route53_record.argo.name
  validation_method = "DNS"
  
  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
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
  values = [
    "${file("argocd-values.yaml")}"
  ]
}

