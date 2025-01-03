locals {
  # - S3 -
  codebuild_artifacts_s3_bucket_name    = "codebuild-artifacts-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
  codepipeline_artifacts_s3_bucket_name = "codepipeline-artifacts-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"

  # - CodeBuild -
  tf_test_codebuild_project_name   = "build-test-codebuild-project"
  tf_deploy_codebuild_project_name = "build-deploy-codebuild-project"

  # - CodeBuild buildspec paths -
  tf_test_buildspec_path = "./pipeline_files/tf-test-buildspec.yml"
  tf_deployspec_path     = "./pipeline_files/tf-deployspec.yml"

  # - CodePipeline -
  validation_codepipeline_pipeline_name = "validation-codepipeline"
  deployment_codepipeline_pipeline_name = "deployment-codepipeline"
}