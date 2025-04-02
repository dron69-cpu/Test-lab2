##############################
# S3 Bucket and Permissions
##############################

resource "aws_s3_bucket" "private_bucket" {
  bucket = "tf-private-bucket-${random_id.rand.hex}"
  acl    = "private"

  tags = {
    Name        = "PrivateAccessBucket"
    Environment = "Dev"
  }
}

resource "random_id" "rand" {
  byte_length = 4
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "tf-private-ec2-s3-access"
  description = "Allow private EC2 instance to access S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:*"],
        Resource = [
          aws_s3_bucket.private_bucket.arn,
          "${aws_s3_bucket.private_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "private_ec2_s3" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}