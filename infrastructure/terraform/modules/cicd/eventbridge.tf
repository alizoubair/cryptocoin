# Create custom event bus
resource "aws_cloudwatch_event_bus" "custom_event_bus" {
  name = "${var.project_prefix}-custom-event-bus"

  tags = merge(
    var.tags,
    {
      "Name" = "${var.project_prefix}-custom-event-bus"
    }
  )
}

# Rule to route events to custom bus
resource "aws_cloudwatch_event_rule" "custom_event_rule" {
  for_each      = var.codepipeline_pipelines
  name          = "${var.project_prefix}-event_rule-${each.value.codepipeline_name}"
  role_arn      = aws_iam_role.eventbridge_event_routing_role.arn
  force_destroy = var.force_destroy
  event_pattern = each.value.codepipeline_type == "branch" ? jsonencode({
    "source" : ["aws.codestar"],
    "detail-type" : ["CodeStar Connection Status Change"],
    "resources" : [aws_codestarconnections_connection.github.arn],
    "detail" : {
      "event" : ["referenceCreated", "referenceUpdated"],
      "referenceType" : ["branch"],
      "referenceName" : ["refs/heads/feature/", "refs/heads/infra"]
    }
    }) : jsonencode({
    "source" : ["aws.codestar"],
    "detail-type" : ["CodeStar Connection Status Change"],
    "resources" : [aws_codestarconnections_connection.github.arn],
    "detail" : {
      "event" : ["pullRequestCreated", "pullRequestUpdated"],
      "destinationRef" : ["refs/heads/main"],
      "pullRequestStatus" : ["Open"]
    }
  })

  tags = merge(
    var.tags,
    {
      "Name" = "${var.project_prefix}-event_rule-${each.value.codepipeline_name}"
    }
  )
}

# Target to route events to custom bus
resource "aws_cloudwatch_event_target" "custom_event_target" {
  for_each      = var.codepipeline_pipelines
  rule          = aws_cloudwatch_event_rule.custom_event_rule[each.key].name
  force_destroy = var.force_destroy
  target_id     = aws_cloudwatch_event_bus.custom_event_bus.name
  arn           = aws_cloudwatch_event_bus.custom_event_bus.arn
  role_arn      = aws_iam_role.eventbridge_event_routing_role.arn
}

# Rule to invoke pipeline from custom bus
resource "aws_cloudwatch_event_rule" "invoke_codepipeline_event_rule" {
  for_each       = var.codepipeline_pipelines
  name           = "${var.project_prefix}-codepipeline_event_rule-${each.value.codepipeline_name}"
  event_bus_name = aws_cloudwatch_event_bus.custom_event_bus.name
  role_arn       = aws_iam_role.eventbridge_invoke_pipeline_role.arn
  force_destroy  = var.force_destroy
  event_pattern = each.value.codepipeline_type == "branch" ? jsonencode({
    "source" : ["aws.codestar"],
    "detail-type" : ["CodeStar Connection Status Change"],
    "resources" : [aws_codestarconnections_connection.github.arn],
    "detail" : {
      "event" : ["referenceCreated", "referenceUpdated"],
      "referenceType" : ["branch"],
      "referenceName" : ["refs/heads/feature/", "refs/heads/infra"]
    }
    }) : jsonencode({
    "source" : ["aws.codestar"],
    "detail-type" : ["CodeStar Connection Status Change"],
    "resources" : [aws_codestarconnections_connection.github.arn],
    "detail" : {
      "event" : ["pullRequestCreated", "pullRequestUpdated"],
      "destinationRef" : ["refs/heads/main"],
      "pullRequestStatus" : ["Open"]
    }
  })

  tags = merge(
    var.tags,
    {
      "Name" = "${var.project_prefix}-codepipeline_event_rule-${each.value.codepipeline_name}"
    }
  )
}

#  Target to invoke pipeline from custom bus
resource "aws_cloudwatch_event_target" "codepipeline_event_target" {
  for_each       = var.codepipeline_pipelines
  rule           = aws_cloudwatch_event_rule.invoke_codepipeline_event_rule[each.key].name
  target_id      = aws_codepipeline.codepipeline[each.key].name
  force_destroy  = var.force_destroy
  arn            = aws_codepipeline.codepipeline[each.key].arn
  role_arn       = aws_iam_role.eventbridge_invoke_pipeline_role.arn
  event_bus_name = aws_cloudwatch_event_bus.custom_event_bus.arn
}