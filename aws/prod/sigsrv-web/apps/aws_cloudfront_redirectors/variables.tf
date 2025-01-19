variable "aws_cloudfront_redirectors" {
  type = map(object({
    domain_names = list(string)
    target_url   = string
  }))
}
