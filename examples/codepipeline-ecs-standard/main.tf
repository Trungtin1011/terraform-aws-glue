module "aws_repos" {
  source = "github.com/Trungtin1011/terraform-aws-resources//submodules/codecommit?ref=v1.2.0"

  ### CodeCommit configurations
  create_codecommit_repo         = true
  codecommit_repo_name           = "ecs-code-repo"
  codecommit_repo_description    = "CodeCommit Repository"
  codecommit_repo_default_branch = "main"
  enable_repo_approval           = false
  create_repo_trigger            = false
  tags                           = {}
}

module "aws_builds" {
  source = "github.com/Trungtin1011/terraform-aws-resources//submodules/codebuild?ref=v1.2.0"

  ### CodeBuild configurations
  create_codebuild_project         = true
  codebuild_project_name           = "application-build"
  codebuild_project_description    = "CodeBuild example"
  codebuild_project_public_access  = false
  codebuild_project_visibility     = "PRIVATE"
  codebuild_project_build_timeout  = 60
  codebuild_project_queued_timeout = 480
  create_codebuild_role            = false
  codebuild_role_arn               = aws_iam_role.codebuild_role.arn


  codebuild_source = {
    type            = "CODECOMMIT"
    location        = "${module.aws_repos.code_repo_arn}"
    git_clone_depth = 1
    git_submodules_config = {
      fetch_submodules = true
    }
    buildspec = "buildspec.yaml"
  }

  codebuild_artifacts = {
    type = "NO_ARTIFACTS"
  }

  codebuild_environment = {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    environment_variable        = []
  }

  codebuild_project_logs_config = {
    cloudwatch_logs = {
      status      = "ENABLED"
      group_name  = "cicd-logs"
      stream_name = "codebuild"
    }
  }

  tags = {}
}

module "aws_pipelines" {
  source = "github.com/Trungtin1011/terraform-aws-resources//submodules/codepipeline?ref=v1.2.0"

  create_pipeline = true
  codepipeline_basic = {
    name           = "application-pipeline"
    execution_mode = "QUEUED"
    pipeline_type  = "V2"
  }
  create_pipeline_role = false
  pipeline_role_arn    = aws_iam_role.codepipeline_role.arn

  pipeline_artifacts = [
    {
      location = module.artifact_bucket.s3_bucket_id
      type     = "S3"
    }
  ]
  pipeline_stages = [
    {
      stage_name = "fetchSourceCode"

      action = {
        action_name      = "codeCommitSrc"
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeCommit"
        version          = "1"
        output_artifacts = ["source_output"]
        run_order        = 1
        configuration = {
          RepositoryName       = "${module.aws_repos.code_repo_name}"
          BranchName           = "main"
          PollForSourceChanges = false ### If = false must use EventBridge to trigger pipeline
          OutputArtifactFormat = "CODE_ZIP"
        }
      }
    },
    {
      stage_name = "buildImage"

      action = {
        action_name      = "appBuild"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        version          = "1"
        input_artifacts  = ["source_output"]
        output_artifacts = ["build_output"]
        run_order        = 1
        configuration = {
          ProjectName   = module.aws_builds.codebuild_project_arn
          PrimarySource = "src"
          BatchEnabled  = false
        }
      }
    },
    {
      stage_name = "manualApproval"

      action = {
        action_name = "approval"
        category    = "Approval"
        owner       = "AWS"
        provider    = "Manual"
        version     = "1"
        run_order   = 1
        configuration = {
          CustomData      = "Dear Approvers! Please review & approve."
          NotificationArn = module.sns_pipeline_approval.topic_arn
        }
      }
    },
    {
      stage_name = "deploytoECS"

      action = {
        action_name     = "standardDeploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "ECS"
        version         = "1"
        input_artifacts = ["build_output"]
        run_order       = 1
        configuration = {
          ClusterName       = module.ecs.cluster_name
          ServiceName       = module.ecs.services["application"].name
          FileName          = "imagedefinitions.json"
          DeploymentTimeout = 15 # mins
        }
      }
    },
  ]
  tags = {}
}

############################
### Supporting resources ###
############################

### SNS topic for sending approval to emails
module "sns_pipeline_approval" {
  source  = "terraform-aws-modules/sns/aws"
  version = "5.4.0"

  # Basic Settings
  create       = true
  name         = "sns-pipeline-approval"
  display_name = "sns-pipeline-approval"

  # Topic Policy Settings
  enable_default_topic_policy = false
  create_topic_policy         = true
  topic_policy_statements = {
    snsPublish = {
      actions = ["sns:Publish"]
      principals = [{
        type        = "Service"
        identifiers = ["codepipeline.amazonaws.com"]
      }]
      conditions = [{
        test     = "StringEquals"
        variable = "AWS:SourceOwner"
        values   = ["${data.aws_caller_identity.current.account_id}"]
      }]
    },
    snsSubscribe = {
      actions = [
        "sns:Subscribe",
        "sns:Receive",
        "sns:GetTopicAttributes"
      ]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }]
      conditions = [{
        test     = "StringEquals"
        variable = "sns:Protocol"
        values   = ["email"]
      }]
    }
  }

  # Subscription Settings
  create_subscription = true
  subscriptions = {
    trungtin = {
      protocol = "email"
      endpoint = "my@email.com"
    }
  }

  # Taggings
  tags = {
    resource_type = "sns"
    resource_name = "sns-pipeline-approval"
  }
}

### S3 bucket for storing artifacts
module "artifact_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket                  = "artifact-s3-bucket"
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
  versioning = {
    enabled = true
  }

  tags = {
    resource_type = "s3"
    resource_name = "artifact-s3-bucket"
  }
}

### Commit trigger CodePipeline
module "pipeline_trigger" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "3.0.0"

  # IAM Role for EventBridge
  create_role        = true
  role_name          = "pipeline-trigger-role"
  role_description   = "EventBridge IAM Role for triggering AWS CodePipeline"
  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "triggerPipeline"
        Effect   = "Allow"
        Resource = ["*"]
        Action = [
          "codepipeline:StartPipelineExecution"
        ]
      }
    ]
  })

  # EventBridge Bus Resources Settings
  create_bus = false

  # EventBridge Rule Resources Settings
  create_rules = true
  rules = {
    pipeline_trigger = {
      "description" = "EventBridge rule for pipeline_trigger"
      "state"       = "ENABLED"
      "event_pattern" = jsonencode(
        { "source" : ["aws.codecommit"],
          "detail-type" : ["CodeCommit Repository State Change"],
          "resources" : ["${module.aws_repos.code_repo_arn}"],
          "detail" : {
            "event" : ["referenceCreated", "referenceUpdated"],
            "referenceType" : ["branch"],
            "referenceName" : ["main"]
          }
        }
      )
    }
  }

  # EventBridge Target Resources Settings
  create_targets = true
  targets = {
    pipeline_trigger = [
      {
        name            = "AWS CodePipeline"
        arn             = "${module.aws_pipelines.pipeline_arn}"
        attach_role_arn = true
      }
    ]
  }

  # Tagging
  tags = {
    resource_type = "eventbridge"
    resource_name = "eventbridge-pipeline-trigger"
  }
}

### IAM role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"
  tags = {}
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "assumeRole"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_role" {
  role = aws_iam_role.codepipeline_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "passIAMRole"
        Effect   = "Allow"
        Resource = "*"
        Action   = ["iam:PassRole"]
      },
      {
        Sid      = "readWriteS3"
        Effect   = "Allow"
        Resource = ["arn:aws:s3:::aws*"]
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:*Object*"
        ]
      },
      {
        Sid      = "accessCodeCommit"
        Effect   = "Allow"
        Resource = ["arn:aws:codecommit:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
        Action = [
          "codecommit:GitPull",
          "codecommit:CancelUploadArchive",
          "codecommit:UploadArchive",
          "codecommit:Get*",
          "codecommit:BatchGet*",
          "codecommit:List*"
        ]
      },
      {
        Sid      = "accessCodeBuild"
        Effect   = "Allow"
        Resource = ["arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:BatchGetBuildBatches",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages",
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:ListBuildsForProject",
          "codebuild:UpdateReport",
          "codebuild:StartBuild",
          "codebuild:StartBuildBatch",
          "codebuild:StopBuild",
          "codebuild:StopBuildBatch"
        ]
      },
      {
        Sid      = "accessCodeDeploy"
        Effect   = "Allow"
        Resource = ["arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
      },
      {
        Sid      = "publishSNS"
        Effect   = "Allow"
        Resource = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
        Action   = ["sns:Publish"]
      },
      {
        Sid      = "deploytoECS"
        Effect   = "Allow"
        Resource = ["*"]
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:TagResource",
          "ecs:UpdateService"
        ]
      },
    ]
  })
}

### IAM role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"
  tags = {}
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "assumeRole"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_role" {
  role = aws_iam_role.codebuild_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "passIAMRole"
        Effect   = "Allow"
        Resource = "*"
        Action   = ["iam:PassRole"]
      },
      {
        Sid      = "writeLogs"
        Effect   = "Allow"
        Resource = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
      },
      {
        Sid      = "readwriteS3"
        Effect   = "Allow"
        Resource = ["arn:aws:s3:::*"]
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:*Object*"
        ]
      },
      {
        Sid      = "pullCodeCommit"
        Effect   = "Allow"
        Resource = ["arn:aws:codecommit:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
        Action   = ["codecommit:GitPull"]
      },
      {
        Sid      = "handleCodeBuild"
        Effect   = "Allow"
        Resource = ["arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
        Action = [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ]
      },
      {
        Sid      = "updateLambda"
        Effect   = "Allow"
        Resource = ["arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"]
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:PublishVersion"
        ]
      },
      {
        Sid      = "buildECRImages"
        Effect   = "Allow"
        Resource = ["*"]
        Action = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken",
          "ecr:GetDownloadUrlForLayer",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}
