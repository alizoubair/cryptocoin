output "tf_state_bucket_name" {
  value = aws_s3_bucket.tf_remote_state_s3_bucket.id
}

output "codestar_connection_arn" {
  value = aws_codestarconnections_connection.github.arn
}