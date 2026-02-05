# Managing our bucket for our website
resource "aws_s3_bucket" "bucket" {
  bucket = var.s3

  tags = merge(var.common_tags, {
    Name = "${var.s3}"
  })
}