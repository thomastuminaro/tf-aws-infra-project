# Managing our bucket for our website
resource "aws_s3_bucket" "bucket" {
  bucket = var.s3

  force_destroy = true

  tags = merge(var.common_tags, {
    Name = "${var.s3}"
  })
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "app" {
  bucket = aws_s3_bucket.bucket.id
  key = "index.html"
  source = "${path.module}/src/index.html"

  etag = filemd5("${path.module}/src/index.html")
}

