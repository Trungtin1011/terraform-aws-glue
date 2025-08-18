### This pipeline sync data from CodeCommit/S3 to S3
module "aws_pipeline" {
  source = "github.com/Trungtin1011/terraform-aws-resources//submodules/codepipeline?ref=v1.2.0"


  ### AWS Developer Tools Connection settings
  enable_additional_settings = false
  additional_settings = {
    connection = {
      connection_name = "test-connection"
      connection_type = "GitHub"
    }
    host = {
      host_name     = "example-host"
      host_endpoint = "https://example-host.com"
      host_type     = "GitHub"
      host_vpc_configs = {
        vpc_id             = "vpc-id"
        subnet_ids         = ["ids"]
        security_group_ids = ["ids"]
      }
    }
  }

  ### CodePipeline basic
  create_pipeline = true
  codepipeline_basic = {
    name           = "example-pipeline"
    execution_mode = "QUEUED"
    pipeline_type  = "V2"
  }

  ### CodePipeline service role (Required)
  create_pipeline_role      = true
  pipeline_role_name        = "example-codepipeline-role"
  pipeline_role_description = "AWS CodePipeline service role"
  pipeline_role_policy      = "additional policy in json format"
  #pipeline_role_arn = # Existing CodePipeline IAM role, use when create_pipeline_role = false

  ### CodePipeline artifacts store (Required)
  pipeline_artifacts = [
    {
      location = "${module.artifact_bucket.s3_bucket_id}"
      type     = "S3"
    }
  ]

  ### CodePipelien stages (Required at least TWO stages)
  pipeline_stages = [
    {
      stage_name = "Source"
      ### CodeCommit source
      action = {
        action_name      = "codeCommitSrc"
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeCommit"
        version          = "1"
        output_artifacts = ["s3_output"]
        run_order        = 1
        configuration = {
          RepositoryName       = "${module.aws_codecommit_repo.code_repo_name}"
          BranchName           = "main"
          PollForSourceChanges = false ### If = false must use EventBridge to trigger pipeline
          OutputArtifactFormat = "CODE_ZIP"
        }
      }
    },
    # {
    #   stage_name = "Source"
    #   ### S3 source
    #   action = {
    #     action_name      = "s3Src"
    #     category         = "Source"
    #     owner            = "AWS"
    #     provider         = "S3"
    #     version          = "1"
    #     output_artifacts = ["s3_output"]
    #     run_order        = 1
    #     configuration = {
    #       S3Bucket             = "${module.source_bucket.s3_bucket_id}"
    #       S3ObjectKey          = "src/hello.py"
    #       PollForSourceChanges = true ### If = false must use EventBridge to trigger pipeline
    #     }
    #   }
    # },
    {
      stage_name = "Deploy"
      ### Deploy to S3
      action = {
        action_name     = "s3Des"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "S3"
        version         = "1"
        input_artifacts = ["s3_output"]
        run_order       = 1
        configuration = {
          BucketName = "${module.destination_bucket.s3_bucket_id}"
          Extract    = true
        }
      }
    },
  ]

  ### CodePipeline custom action
  pipeline_custom_actions = [
    {
      category      = "Build"
      provider_name = "Terraform"
      version       = 1
      input_artifact_details = {
        minimum_count = 0
        maximum_count = 5
      }
      output_artifact_details = {
        minimum_count = 0
        maximum_count = 5
      }
    },
  ]

  # ### CodePipeline webhook
  # pipeline_webhook = {
  #   name            = "example-pipeline-webhook"
  #   authentication  = "UNAUTHENTICATED"
  #   target_action   = "Source"
  #   filter = [
  #     {
  #       json_path    = "$.ref"
  #       match_equals = "refs/heads/main"
  #     },
  #     {
  #       json_path    = "$.ref"
  #       match_equals = "refs/heads/test"
  #     }
  #   ]
  # }

  tags = var.tags
}
