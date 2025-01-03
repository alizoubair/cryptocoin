# Dynamically create the CodePipelines
resource "aws_codepipeline" "codepipeline" {
  for_each = var.codepipeline_pipelines

  name     = each.value.codepipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = each.value.artifact_store_location
    type     = "S3"
  }

  dynamic "stage" {
    for_each = each.value.stages
    content {
      name = stage.value.name
      dynamic "action" {
        for_each = stage.value.action
        content {
          name             = action.value.name
          category         = action.value.category
          owner            = action.value.owner
          provider         = action.value.provider
          version          = action.value.version
          input_artifacts  = action.value.input_artifacts
          output_artifacts = action.value.output_artifacts
          configuration    = action.value.configuration
        }
      }
    }
  }

  tags = merge(
    var.tags,
    each.value.tags
  )
}