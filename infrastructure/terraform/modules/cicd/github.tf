# Create GitHub Connection
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_prefix}-github-connection"
  provider_type = "GitHub"

  tags = {
    Environment = "CI/CD"
    Purpose     = "GitHub Connection"
  }
}