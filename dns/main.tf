

data "aws_route53_zone" "devopsworksio" {
  name = "devopsworks.io"
}

resource "aws_route53_zone" "tools" {
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
  domain = "vpc"
}

resource "aws_acm_certificate" "argo" {
  domain_name       = "tools.devopsworks.io"
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
  name            = tolist(aws_acm_certificate.argo.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.argo.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.argo.domain_validation_options)[0].resource_record_type
  zone_id         = aws_route53_zone.tools.id
  ttl             = 60
}

resource "aws_acm_certificate_validation" "hello_cert_validate" {
  certificate_arn         = aws_acm_certificate.argo.arn
  validation_record_fqdns = [aws_route53_record.hello_cert_dns.fqdn]
}
