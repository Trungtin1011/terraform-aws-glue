module "aws_codedeploy" {
  source = "github.com/Trungtin1011/terraform-aws-resources//submodules/codedeploy?ref=v1.2.0"

  ### AWS CodeDeploy settings
  create_codedeploy_application = true
  codedeploy_application = {
    name     = "example-codedeploy-app"
    platform = "Lambda"
  }

  ### Custom CodeDeploy deployment config
  use_custom_deployment_config = true
  custom_codedeploy_deployment_config = {
    name     = "example-deployment-config"
    platform = "Lambda"
    traffic_routing = {
      type = "TimeBasedLinear"

      time_based_linear = {
        interval   = 10
        percentage = 10
      }
    }
  }

  ### CodeDeploy deployment group
  create_codedeploy_deployment_group = true
  codedeploy_deployment_group_name   = "example-deployment-group"
  codedeploy_deployment_group_deployment_style = {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN" # IN_PLACE, BLUE_GREEN
  }
  # If use_custom_deployment_config = true, this will be overrided by custom_codedeploy_deployment_config
  codedeploy_deployment_group_deployment_config_name = "CodeDeployDefault.OneAtATime"

  codedeploy_deployment_group_ec2_tag_set = [
    {
      key   = "tagset-key-1"
      type  = "KEY_AND_VALUE"
      value = "tagset-value-1"
    },
    {
      key   = "tagset-key-2"
      type  = "KEY_AND_VALUE"
      value = "tagset-value-2"
    }
  ]

  codedeploy_deployment_group_ec2_tag_filter = [
    {
      key   = "tagfilter-key-1"
      type  = "KEY_AND_VALUE"
      value = "tagfilter-value-1"
    },
    {
      key   = "tagfilter-key-2"
      type  = "KEY_AND_VALUE"
      value = "tagfilter-value-2"
    }
  ]

  ### CodeDeploy deployment group service role (Required)
  create_codedeploy_deployment_role      = true
  codedeploy_deployment_role_name        = "example-deployment-group-role"
  codedeploy_deployment_role_description = "CodeBuild IAM service role"
  codedeploy_deployment_role_policy      = "custom-policy-in-json-format"
  # codedeploy_deployment_role_arn = # Existing IAM role, use when create_codedeploy_deployment_role = false

  ### CodeDeploy application notification
  codedeploy_notifications = {
    detail_type = "BASIC"
    event_type_ids = [
      "codedeploy-application-deployment-failed",
      "codedeploy-application-deployment-succeeded"
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
