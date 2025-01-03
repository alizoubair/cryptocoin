# - Project prefix -
variable "project_prefix" {
  type        = string
  description = "Prefix for project resources"
  default     = "cryptocoin"
}

# - Tags -
variable "tags" {
  type        = map(any)
  description = "Default tags for project resources"
  default = {
    Project = "cryptocoin"
  }
}

# - S3 -
variable "tf_remote_state_s3_bucket_name" {
  type        = string
  description = "S3 bucket name for terraform remote state"
  default     = "cryptocoin-terraform-state"
}

variable "artifacts_s3_buckets" {
  description = "List of S3 buckets to create"
  type = map(object({
    bucket_name = optional(string, null)
    tags                  = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for bucket in values(var.artifacts_s3_buckets) : (
        length(bucket.bucket_name) >= 3 &&
        length(bucket.bucket_name) <= 63
      )
    ])
    error_message = "artifacts_bucket_name must be between 3 and 63 characters"
  }
}

# - EventBridge -
variable "force_destroy" {
  type        = bool
  description = "Enable force destroy on all EventBridges rules"
  default     = true
}

# - CodeBuild -
variable "codebuild_projects" {
  description = "List of CodeBuild projects to create"
  type = map(object({
    codebuild_name = string
    description    = string
    build_timeout  = optional(number, 60)

    compute_type    = optional(string, "BUILD_GENERAL1_SMALL")
    image           = optional(string, "aws/codebuild/amazonlinux2-x86_64-standard:3.0")
    type            = optional(string, "LINUX_CONTAINER")
    privileged_mode = optional(bool, false)

    source_type      = optional(string, "CODEPIPELINE")
    buildspec = optional(string, null)

    artifacts_type = optional(string, "CODEPIPELINE")

    cache_type     = optional(string, "NO_CACHE")
    cache_location = optional(string, null)

    group_name  = optional(string, "")
    stream_name = optional(string, "")
    status   = optional(string, null)
    s3_logs_location = optional(string, null)

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for project in values(var.codebuild_projects) : (
        length(project.codebuild_name) >= 3 &&
        length(project.codebuild_name) <= 40
      )
    ])
    error_message = "codebuild_name must be between 3 and 40 characters"
  }
}

# - CodePipeline
variable "codepipeline_pipelines" {
  description = "List of CodePipelines to create"
  type = map(object({
    codepipeline_name = string
    codepipeline_type = optional(string, null)
    description       = string
    artifact_store_location = optional(string, null)
    stages = list(any)
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for pipeline in values(var.codepipeline_pipelines) : (
        length(pipeline.codepipeline_name) >= 3 &&
        length(pipeline.codepipeline_name) <= 40
      )
    ])
    error_message = "codepipeline_name must be between 3 and 40 characters"
  }
}