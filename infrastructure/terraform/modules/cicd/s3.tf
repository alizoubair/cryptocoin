# Dynamically create artifacts S3 buckets
resource "aws_s3_bucket" "s3_artifacts_bucket" {
  for_each = var.artifacts_s3_buckets

  bucket        = each.value.bucket_name
  force_destroy = true

  tags = merge(
    var.tags,
    each.value.tags
  )
}

# Create the S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_sse" {
  for_each = var.artifacts_s3_buckets
  bucket   = each.value.bucket_name

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  for_each = var.artifacts_s3_buckets
  bucket   = each.value.bucket_name

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}