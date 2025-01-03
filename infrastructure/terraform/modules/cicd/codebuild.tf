# Dynamically create CodeBuild projects
resource "aws_codebuild_project" "codebuild_project" {
  for_each = var.codebuild_projects

  name          = each.value.codebuild_name
  description   = each.value.description
  build_timeout = each.value.build_timeout
  service_role  = aws_iam_role.codebuild_role.arn
  environment {
    compute_type    = each.value.compute_type
    image           = each.value.image
    type            = each.value.type
    privileged_mode = each.value.privileged_mode
  }
  source {
    type      = each.value.source_type
    buildspec = file(each.value.buildspec)
  }
  artifacts {
    type = each.value.artifacts_type
  }
  cache {
    type     = each.value.cache_type
    location = each.value.cache_location
  }
  logs_config {
    cloudwatch_logs {
      group_name  = each.value.group_name
      stream_name = each.value.stream_name
    }
    s3_logs {
      status   = each.value.status
      location = each.value.s3_logs_location
    }
  }

  tags = merge(
    var.tags,
    each.value.tags
  )
}