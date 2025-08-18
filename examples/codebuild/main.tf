module "aws_codebuild" {
  source = "github.com/Trungtin1011/terraform-aws-resources//submodules/codebuild?ref=v1.2.0"

  ### CodeBuild project
  create_codebuild_project         = true
  codebuild_project_name           = "example-build-project"
  codebuild_project_description    = "CodeBuild example"
  codebuild_project_public_access  = false
  codebuild_project_visibility     = "PRIVATE"
  codebuild_project_build_timeout  = 60
  codebuild_project_queued_timeout = 480
  codebuild_project_logs_config = {
    cloudwatch_logs = {
      group_name  = "example-cw-loggroup"
      status      = "ENABLED"
      stream_name = "codebuild/"
    }
  }

  ### CodeBuild service role (Required)
  create_codebuild_role      = true
  codebuild_role_name        = "example-codebuild-role"
  codebuild_role_description = "CodeBuild IAM service role"
  codebuild_role_policy      = "custom-policy-in-json-format"
  #codebuild_role_arn               = # Existing IAM role, use when create_codebuild_role = false

  ### CodeBuild source (Required)
  codebuild_source = {
    type            = "CODECOMMIT"
    location        = "${module.aws_codecommit_repo.code_repo_arn}"
    git_clone_depth = 1
    git_submodules_config = {
      fetch_submodules = true
    }
    buildspec = "buildspec.yaml"
  }

  ### CodeBuild artifacts (Required)
  codebuild_artifacts = {
    type = "NO_ARTIFACTS" # CODEPIPELINE, NO_ARTIFACTS, S3
  }

  ### CodeBuild environment (Required)
  codebuild_environment = {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
    environment_variable = [
      {
        name  = "LAMBDA_FUNC_NAME"
        value = "${module.lambda_function.lambda_function_name}"
        type  = "PLAINTEXT" ### PARAMETER_STORE, SECRETS_MANAGER
      },
      {
        name  = "VARIABLE_2"
        value = "VALUE2"
        type  = "PLAINTEXT"
      }
    ]
  }

  # ### Webhook integration with GitHub, GitHub Enterprise Server, GitLab, GitLab Self Managed, and Bitbucket
  # codebuild_project_webhook = {
  #   build_type = "BUILD"
  #   filter_group = [
  #     {
  #       type    = "EVENT"
  #       pattern = "PUSH"
  #     },
  #     {
  #       type    = "BASE_REF"
  #       pattern = "master"
  #     }
  #   ]
  # }

  ### CodeBuild report group
  codebuild_report_group = {
    name = "example-report-group"
    type = "TEST"
    export_config = {
      type = "S3" # S3 or NO_EXPORT
      s3_destination = {
        bucket         = "example-s3-bucket"
        encryption_key = "arn:aws:kms:ap-southeast-1:963626856932:alias/aws/s3"
      }
    }
  }

  ### CodeBuild report group policy
  codebuild_report_group_policy = [
    {
      Sid       = "getReports"
      Principal = { AWS = "${data.aws_caller_identity.current.account_id}" }
      Action    = ["codebuild:BatchGetReportGroups", "codebuild:BatchGetReports"]
    },
    {
      Sid       = "listReports"
      Principal = { AWS = "${data.aws_caller_identity.current.account_id}" }
      Action    = ["codebuild:ListReportsForReportGroup"]
    }
  ]

  # ### CodeBuild credential for GitHub, GitHub Enterprise, Bitbucket, ...
  # codebuild_credential = {
  #   auth_type   = "PERSONAL_ACCESS_TOKEN"
  #   server_type = "GITHUB"
  #   token       = "example"
  #   username    = "example-user"
  # }

  ### CodeBuild project notifications
  codebuild_notifications = {
    detail_type = "BASIC"
    event_type_ids = [
      "codebuild-project-build-state-failed",
      "codebuild-project-build-state-succeeded"
    ]
    targets = [
      {
        address = "arn:aws:sns:ap-southeast-1:123456789012:sns-test-topic-1"
        type    = "SNS" # AWS Chatbot (Teams), AWS Chatbot (Slack)
      },
      {
        address = "arn:aws:sns:ap-southeast-1:123456789012:sns-test-topic-2"
        type    = "SNS"
      }
    ]
  }

  tags = var.tags
}
