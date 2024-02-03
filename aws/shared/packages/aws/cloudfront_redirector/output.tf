output "domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "validation_emails" {
  value = aws_acm_certificate.this.validation_emails
}
