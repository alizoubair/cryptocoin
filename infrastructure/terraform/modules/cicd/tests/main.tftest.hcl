# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Global Testing Variables
variables {
  # - Test S3 Buckets -
  artifacts_s3_buckets = {
    test_codepipeline_artifacts_bucket_1 : {
      bucket_name = "tf-test-artifacts"
      tags = {
        Environment = "CI/CD"
        Purpose     = "Testing"
      }
    }
  }

  # - Test CodeBuild Projects -
  codebuild_projects = {
    "tf_test_test_project_1" : {
      codebuild_name = "tf-test-test-project-1"
      description    = "Test CodeBuild Test Project 1"
      buildspec      = <<-EOF
        version: 0.2
                phases:
          pre-build:
            commands:
              - echo "Initializing Terraform..."
              - Terraform init
              - Terraform validate
          build:
            commands:
              - echo "Running Terraform Test Framework..."
              - Terraform test
      EOF
      cache = {
        type = "NO_CACHE"
      }
      logs_config = {
        cloudwatch_logs = {
          group_name  = "tf-test-test-project-1-logs"
          stream_name = "tf-test-test-project-1-stream"
        }
        s3_logs = {
          status = "DISABLED"
        }
      }
      tags = {
        Environment = "CI/CD"
        Purpose     = "Testing"
      }
    }

    "test_deploy_project_1" : {
      codebuild_name = "test-deploy-project-1"
      description    = "Test CodeBuild Deploy Project 1"
      buildspec      = <<-EOF
        version: 0.2
                phases:
          pre-build:
            commands:
              - echo "Initializing Terraform..."
              - Terraform init
              - Terraform validate
          build:
            commands:
              - echo "Applying Terraform configuration..."
              - terraform apply -auto-approve
      EOF
      cache = {
        type = "NO_CACHE"
      }
      logs_config = {
        cloudwatch_logs = {
          group_name  = "test-deploy-project-1-logs"
          stream_name = "test-deploy-project-1-stream"
        }
        s3_logs = {
          status = "DISABLED"
        }
      }
      tags = {
        Environment = "CI/CD"
        Purpose     = "Testing"
      }
    }
  }

  # - Test CodePipeline pipelines -
  codepipeline_pipelines = {
    # Validation Pipelines
    "test_validation_pipeline_1" : {
      codepipeline_name = "test-validation-pipeline-1"
      description       = "Test CodePipeline Validation Pipeline 1"
      artifact_store_location = "tf-test-artifacts"
      tags = {
        Environment = "CI/CD"
        Purpose     = "Testing"
      }

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
              configuration    = {
                ConnectionArn = "arn:aws:codestar-connections:us-east-1:123456789012:connection/test-connection"
                FullRepositoryId = "test-repo-id"
                BranchName     = "main"
              }
              input_artifacts  = []
              output_artifacts = [
                "source_output_artifacts"
              ]
              run_order        = 1
            }
          ]
        },

        # Run Terraform Test Framework
        {
          name = "Build_TF_Test"
          action = [
            {
              name             = "Test"
              category         = "Test"
              owner            = "AWS"
              provider         = "CodeBuild"
              version          = "1"
              configuration    = {
                ProjectName = "tf_test_test_project_1"
              }
              input_artifacts  = ["source_output_artifacts"]
              output_artifacts = ["build_test_output_artifacts"]
              run_order        = 2
            }
          ]
        }
      ]
    }
  }
}

# - Unit Tests -
run "input_validation" {
  command = plan

  # Intentional invalid input to test validation
  variables {
    # CodeBuild - Intentional project name that is longer than max of 40 characters
    codebuild_projects = {
      "tf_test_test_project_1" : {
        codebuild_name = "this_is_a_project_name_and_it_is_longer_than_40_characters"
        description    = "Test CodeBuild Test Project 1"
        buildspec      = <<-EOF
          version: 0.2
                  phases:
            pre-build:
              commands:
                - echo "Initializing Terraform..."
                - Terraform init
                - Terraform validate
            build:
              commands:
                - echo "Running Terraform Test Framework..."
                - Terraform test
        EOF
        cache = {
          type = "NO_CACHE"
        }
        logs_config = {
          cloudwatch_logs = {
            group_name  = "tf-test-test-project-1-logs"
            stream_name = "tf-test-test-project-1-stream"
          }
          s3_logs = {
            status = "DISABLED"
          }
        }
        tags = {
          Environment = "CI/CD"
          Purpose     = "Testing"
        }
      }
    }
  }

  # Check for intentional failure of variables defined above
  expect_failures = [
    var.codebuild_projects
  ]
}

# - End-to-End Tests -
run "e2e_test" {
  command = apply

  # Assertions
  # CodeBuild - Ensure projects have the correct names after creation
  assert {
    condition     = aws_codebuild_project.codebuild_project["tf_test_test_project_1"].name == "tf-test-test-project-1"
    error_message = "CodeBuild Project (${aws_codebuild_project.codebuild_project["tf_test_test_project_1"].name}) name didn't match the expected value (tf-test-test-project-1)."
  }

  # CodePipeline - Ensure pipelines have the correct names after creation
  assert {
    condition     = aws_codepipeline.codepipeline["test_validation_pipeline_1"].name == "test-validation-pipeline-1"
    error_message = "CodePipeline Pipeline (${aws_codepipeline.codepipeline["test_validation_pipeline_1"].name}) name didn't match the expected value (test-validation-pipeline-1)."
  }
}