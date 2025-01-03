# Create the Remote State S3 bucket
resource "aws_s3_bucket" "tf_remote_state_s3_bucket" {
  bucket = var.tf_remote_state_s3_bucket_name
  force_destroy = true

  tags = var.tags
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "tf_remote_state_s3_bucket_versioning" {
  bucket = aws_s3_bucket.tf_remote_state_s3_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Create the S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_remote_state_s3_sse" {
  for_each = var.artifacts_s3_buckets
  bucket   = each.value.bucket_name

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "tf_remote_state_s3_bucket_public_access_block" {
  for_each = var.artifacts_s3_buckets
  bucket   = each.value.bucket_name

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}