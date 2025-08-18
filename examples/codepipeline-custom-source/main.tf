### This pipeline define a third-party Git repository as CodePipeline source stage
module "tf_pipeline" {
  source = "github.com/Trungtin1011/terraform-aws-resources//submodules/codepipeline?ref=v1.2.0"

  create_pipeline = true
  codepipeline_basic = {
    name           = "${local.prefix}-terraform-pipeline"
    execution_mode = "QUEUED"
    pipeline_type  = "V2"
  }
  create_pipeline_role = false
  pipeline_role_arn    = aws_iam_role.codepipeline_role.arn

  pipeline_artifacts = [
    {
      location = "artifact-bucket-001"
      type     = "S3"
    }
  ]

  ### CodePipeline custom action
  pipeline_custom_actions = [
    {
      category      = "Source"
      provider_name = "SourceAzureDevOpsRepos"
      version       = 1
      input_artifact_details = {
        minimum_count = 0
        maximum_count = 0
      }
      output_artifact_details = {
        minimum_count = 1
        maximum_count = 1
      }
      configuration_property = [
        {
          name        = "Credentials"
          description = "<user:password> or <access_token> that has read access to Azure Repos"
          queryable   = false
          required    = true
          key         = false
          secret      = false
          type        = "String"
        },
        {
          name        = "RepoUrl"
          description = "Azure Repos URL in form of: {domain}/{organization}/{project}/_git/{repository}"
          queryable   = false
          required    = true
          key         = false
          secret      = false
          type        = "String"
        },
        {
          name        = "Branch"
          description = "Name of the tracked Branch"
          queryable   = false
          required    = true
          key         = false
          secret      = false
          type        = "String"
        }
      ]
      settings = { #https://{credentials}@{domain}/{organization}/{project}/_git/{repository}
        entity_url_template    = "https://{Config:Credentials}@{Config:RepoUrl}?version=GB{Config:Branch}"
        execution_url_template = "https://{Config:Credentials}@{Config:RepoUrl}?version=GB{Config:Branch}"
      }
    }
  ]
  pipeline_stages = [
    {
      stage_name = "AzureReposTerraformSource"

      action = {
        action_name      = "fetchTerraformSource"
        category         = "Source"
        owner            = "Custom"
        provider         = "SourceAzureDevOpsRepos"
        version          = "1"
        output_artifacts = ["src_output"]
        region           = "${data.aws_region.current.name}"
        run_order        = 1
        configuration = {
          PipelineName = "${local.prefix}-terraform-pipeline"
          Credentials  = ""
          RepoUrl      = "dev.azure.com/organization/project/_git/repository"
          Branch       = "main"
        }
      }
    },
    {
      stage_name = "ManualApproval"

      action = {
        action_name = "manualApproval"
        category    = "Approval"
        owner       = "AWS"
        provider    = "Manual"
        version     = "1"
        region      = "${data.aws_region.current.name}"
        run_order   = 1
        configuration = {
          CustomData = "Dear Approvers! Please click"
        }
      }
    }
  ]

  ### CodePipeline webhook
  pipeline_webhook = {
    name           = "${local.prefix}-terraform-pipeline-webhook"
    authentication = "UNAUTHENTICATED"
    target_action  = "Source"
    filter = [
      {
        json_path    = "$.resource.refUpdates..name"
        match_equals = "refs/heads/main"
      }
    ]
  }

  tags = var.tags
}

output "pipeline_webhook_url" {
  value = module.tf_pipeline.pipeline_webhook_url
}
