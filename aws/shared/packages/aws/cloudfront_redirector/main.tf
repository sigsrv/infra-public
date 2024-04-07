module "metadata" {
  source = "../../../modules/aws/metadata"
}

locals {
  env  = module.metadata.env
  name = module.metadata.name
}

resource "aws_acm_certificate" "this" {
  provider = aws.global

  domain_name               = var.domain_names[0]
  subject_alternative_names = slice(var.domain_names, 1, length(var.domain_names))
  validation_method         = "EMAIL"

  tags = {
    Name = local.name
  }
}

resource "aws_s3_bucket" "this" {
  provider = aws
  bucket   = var.domain_names[0]

  tags = {
    Name = var.domain_names[0]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_distribution" "this" {
  provider = aws.global

  enabled     = true
  aliases     = var.domain_names
  price_class = "PriceClass_200"

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.this.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  origin {
    domain_name = aws_s3_bucket.this.bucket_domain_name
    origin_id   = "main"
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    target_origin_id       = "main"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.this.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["KR"]
    }
  }

  tags = {
    Name = local.name
  }
}

resource "aws_cloudfront_function" "this" {
  provider = aws.global
  publish  = true # debug only

  name    = replace(local.name, ".", "-")
  runtime = "cloudfront-js-2.0"
  code    = <<EOF
function handler(event) {
  var request = event.request;
  var headers = request.headers;

  if (["/", "/index", "/index.htm", "/index.html"].includes(request.uri)) {
    return {
      statusCode: 302,
      statusDescription: 'Found',
      headers: { "location": { "value": "${var.target_url}" } }
    };
  } else if (request.uri === "/robots.txt") {
    return {
      statusCode: 200,
      statusDescription: "OK",
      headers: { "content-type": { "value": "text/plain" } },
      body: "User-agent: *\nDisallow: /\n"
    };
  } else {
    return {
      statusCode: 404,
      statusDescription: "Not Found",
      headers: { "content-type": { "value": "text/plain" } },
      body: "Not Found"
    };
  }
}
EOF
}

resource "aws_route53_record" "this" {
  for_each = var.route53_records

  zone_id = each.value.zone_id
  name    = each.value.name != null ? each.value.name : ""
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
