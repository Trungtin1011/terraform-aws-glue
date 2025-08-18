module "aws_codecommit_repo" {
  source = "github.com/Trungtin1011/terraform-aws-resources//submodules/codecommit?ref=v1.2.0"

  ### CodeCommit repository
  create_codecommit_repo         = true
  codecommit_repo_name           = "example-codecommit-repo"
  codecommit_repo_description    = "CodeCommit Repository"
  codecommit_repo_default_branch = "main"

  ### CodeCommit approval
  enable_repo_approval      = true
  codecommit_repo_approvers = ["arn:aws:sts::123456789012:assumed-role/CodeCommitReview/*"]
  number_of_approvers       = 2

  ### CodeCommit approval
  create_repo_trigger      = false
  trigger_on_all_branches  = false   # If false, trigger on codecommit_repo_default_branch only
  repo_trigger_events      = ["all"] # all, updateReference, createReference, deleteReference.
  repo_trigger_destination = "arn:aws:sns:ap-southeast-1:123456789012:sns-test-topic"

  ### CodeCommit notification rules
  codecommit_notifications = {
    detail_type = "BASIC"
    event_type_ids = [
      "codecommit-repository-comments-on-commits",
      "codecommit-repository-comments-on-pull-requests"
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
