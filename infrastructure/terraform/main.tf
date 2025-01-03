module "cicd" {
  source = "./modules/cicd"

  # - Create S3 Buckets -
  artifacts_s3_buckets = {
    codebuild_artifacts_bucket : {
      bucket_name = local.codebuild_artifacts_s3_bucket_name
      tags = {
        Environment = "CI/CD"
        Purpose     = "Build Artifacts Bucket"
      }
    },

    codepipeline_artifacts_bucket : {
      bucket_name = local.codepipeline_artifacts_s3_bucket_name
      tags = {
        Environment = "CI/CD"
        Purpose     = "Pipeline Artifacts Bucket"
      }
    }
  }

  # - Create CodeBuild projects -
  codebuild_projects = {
    tf_test_codebuild_project : {
      codebuild_name = local.tf_test_codebuild_project_name
      description    = "Codebuild project that uses the Terraform Test Framework to test the CI/CD"
      buildspec      = local.tf_test_buildspec_path
      cache = {
        type     = "S3"
        location = "${local.codebuild_artifacts_s3_bucket_name}/cache"
      }
      logs_config = {
        cloudwatch_logs = {
          group_name  = "/aws/codebuild/${local.tf_test_codebuild_project_name}"
          stream_name = "tf_test_codebuild_project"
        }
        s3_logs = {
          status   = "ENABLED"
          location = "${local.codebuild_artifacts_s3_bucket_name}/tf_test_codebuild_project"
        }
      }
      tags = {
        Environment = "CI/CD"
        Purpose     = "Testing"
      }
    },

    tf_deploy_codebuild_project : {
      codebuild_name = local.tf_deploy_codebuild_project_name
      description    = "CodeBuild project that deploys the infrastructure using Terraform"
      buildspec      = local.tf_deployspec_path
      cache = {
        type     = "S3"
        location = "${local.codebuild_artifacts_s3_bucket_name}/cache"
      }
      logs_config = {
        cloudwatch_logs = {
          group_name  = "/aws/codebuild/${local.tf_deploy_codebuild_project_name}"
          stream_name = "tf_deploy_codebuild_project"
        }
        s3_logs = {
          status   = "ENABLED"
          location = "${local.codebuild_artifacts_s3_bucket_name}/tf_deploy_codebuild_project"
        }
      }
      tags = {
        Environment = "CI/CD"
        Purpose     = "Deployment"
      }
    }
  }

  # - Create CodePipeline projects -
  codepipeline_pipelines = {
    validation_pipeline : {
      codepipeline_name = local.validation_codepipeline_pipeline_name
      codepipeline_type = "branch"
      description       = "Validation Pipeline"
      artifact_store_location = local.codepipeline_artifacts_s3_bucket_name

      stages = [
        # Clone from GitHub and store contents in artifacts S3 Buckets
        {
          name = "Source"
          action = [
            {
              name             = "Source"
              category         = "Source"
              owner            = "AWS"
              provider         = "CodeStarSourceConnection"
              version          = "1"
              output_artifacts = ["SourceArtifact"]
              configuration = {
                ConnectionArn    = module.cicd.codestar_connection_arn
                FullRepositoryId = var.github_repository
                BranchName           = "{feature/*,infra/*}"
              }
              input_artifacts  = []
              output_artifacts = ["source_output_artifacts"]
              run_order        = 1
            }
          ]
        },

        # Run Terraform Test Framework
        {
          name = "Build_TF_Test"
          action = [
            {
              name             = "Build_TF_Test"
              category         = "Build"
              owner            = "AWS"
              provider         = "CodeBuild"
              version          = "1"
              input_artifacts  = ["source_output_artifacts"]
              output_artifacts = ["validation_output_artifacts"]
              configuration = {
                ProjectName = local.tf_test_codebuild_project_name
              }
              input_artifacts  = ["source_output_artifacts"]
              output_artifacts = ["build_tf_test_output_artifacts"]
              run_order        = 2
            }
          ]
        }
      ]

      tags = {
        Environment = "CI/CD"
        Purpose     = "Validation Pipeline"
      }
    }

    deployment_pipeline : {
      codepipeline_name = local.deployment_codepipeline_pipeline_name
      codepipeline_type = "main"
      description       = "Deployment Pipeline"
      artifact_store_location = local.codepipeline_artifacts_s3_bucket_name

      stages = [
        # Clone from GitHub and store contents in artifacts S3 Buckets
        {
          name = "Source"
          action = [
            {
              name             = "Source"
              category         = "Source"
              owner            = "AWS"
              provider         = "CodeStarSourceConnection"
              version          = "1"
              output_artifacts = ["SourceArtifact"]
              configuration = {
                ConnectionArn    = module.cicd.codestar_connection_arn
                FullRepositoryId = var.github_repository
                BranchName           = "{feature/*,infra/*}"
              }
              input_artifacts  = []
              output_artifacts = ["source_output_artifacts"]
              run_order        = 1
            }
          ]
        },

        # Run Terraform Test Framework
        {
          name = "Build_TF_Test"
          action = [
            {
              name             = "Build_TF_Test"
              category         = "Build"
              owner            = "AWS"
              provider         = "CodeBuild"
              version          = "1"
              input_artifacts  = ["source_output_artifacts"]
              output_artifacts = ["deployment_output_artifacts"]
              configuration = {
                ProjectName = local.tf_test_codebuild_project_name
              }
              input_artifacts  = ["source_output_artifacts"]
              output_artifacts = ["build_tf_test_output_artifacts"]
              run_order        = 2
            }
          ]
        },

        # Apply Terraform
        {
          name = "Build_TF_Deploy"
          action = [
            {
              name            = "Build_TF_Deploy"
              category        = "Build"
              owner           = "AWS"
              provider        = "CodeBuild"
              version         = "1"
              input_artifacts = ["build_tf_test_output_artifacts"]
              configuration = {
                ProjectName = local.tf_deploy_codebuild_project_name
              }
              input_artifacts  = ["source_output_artifacts"]
              output_artifacts = ["build_tf_deploy_output_artifacts"]
              run_order        = 3
            }
          ]
        }
      ]

      tags = {
        Environment = "CI/CD"
        Purpose     = "Deployment Pipeline"
      }
    }
  }
}