##############################
# ACM Certificate
##############################

resource "aws_acm_certificate" "self_signed" {
  domain_name       = "test.cdcmg.click"
  validation_method = "DNS"

  tags = {
    Name = "tf-self-signed"
  }

  lifecycle {
    create_before_destroy = true
  }
}