# Create SES Email Identity (Domain type) with: 
#  - Verify SES domain
#  - Configuration Set 
#  - CloudWatch Event Destination 
#  - SNS Event Destination
module "domain_identity" {
  source = "github.com/Trungtin1011/terraform-aws-resources//submodules/ses-v2?ref=v1.2.0"

  ### Configuration set setting
  delivery_max_seconds           = 300
  delivery_tls_policy            = "OPTIONAL"
  enable_reputation_metrics      = true
  enable_email_sending           = true
  append_suppression_list_on     = ["BOUNCE", "COMPLAINT"]
  enable_email_tracking          = true
  email_tracking_redirect_domain = "https://example.com/redirect"
  enable_vdm_options             = true
  vdm_engagement_metrics         = "ENABLED"
  vdm_optimized_shared_delivery  = "ENABLED"

  ### Create & Verify SESv2 Domain Identity with Easy DKIM
  email_identity              = "example.com"
  verify_domain_identity      = true
  domain_zone_id              = "Z1234567890"
  domain_region               = "ap-southeast-1"
  easy_dkim_key_length        = "RSA_2048_BIT"
  
  ### Create custom MAIL FROM domain
  create_mail_from_domain     = true
  mail_from_failure_behavior  = "USE_DEFAULT_VALUE"

  ### Create additional SESv2 Email identities to share the same Configuration Set
  additional_email_identities = []

  ### Create events destination
  events_send_to_cloudwatch   = ["REJECT", "BOUNCE", "COMPLAINT"]
  enable_sns_notifications    = true
  events_send_to_sns          = ["REJECT", "BOUNCE", "COMPLAINT"]
  sns_notification_arns       = ["existing_sns_topic_arn"]
  tags                        = var.tags
}

# Create SES Email Identity (Email type) with: 
#  - Configuration Set 
#  - CloudWatch Event Destination 
#  - SNS Event Destination
module "email_identity" {
  source = "github.com/Trungtin1011/terraform-aws-resources//submodules/ses-v2?ref=v1.2.0"

  ### Create SESv2 Email Identity
  email_identity            = "user_id@example.com"

  ### Create custom MAIL FROM domain
  create_mail_from_domain     = true
  mail_from_domain            = "example.com"
  mail_from_failure_behavior  = "USE_DEFAULT_VALUE"
  domain_zone_id              = "Z1234567890"
  domain_region               = "ap-southeast-1"

  ### Create events destination
  events_send_to_cloudwatch = ["REJECT", "BOUNCE", "COMPLAINT"]
  enable_sns_notifications  = true
  events_send_to_sns        = ["REJECT", "BOUNCE", "COMPLAINT"]
  sns_notification_arns     = ["existing_sns_topic_arn"]
  tags                      = var.tags
}
