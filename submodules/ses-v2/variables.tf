variable "tags" {
  description = "Tagging for AWS SESv2 components"
  type        = any
  default = {
    iac = "terraform"
  }
}


# SESv2 Configuration Set
variable "delivery_max_seconds" {
  type        = number
  description = "Maximum amount in seconds that Amazon SES API v2 will attempt delivery of email. [300,50400]"
  default     = 300
}

variable "delivery_tls_policy" {
  type        = string
  description = "Specifies whether messages that use the configuration set are required to use Transport Layer Security (TLS)."
  default     = "OPTIONAL"
}

variable "delivery_sending_pool_name" {
  type        = string
  description = "The name of the dedicated IP pool to associate with the configuration set."
  default     = null
}

variable "enable_reputation_metrics" {
  type        = bool
  description = "Whether to track reputation metrics for the configuration set."
  default     = true
}

variable "enable_email_sending" {
  type        = bool
  description = "Whether to enable email sending for the configuration set."
  default     = true
}

variable "append_suppression_list_on" {
  type        = list(string)
  description = "The reasons that email addresses are automatically added to the suppression list for your account."
  default     = ["BOUNCE", "COMPLAINT"]
}

variable "enable_email_tracking" {
  type        = bool
  description = "Defines the open and click tracking options for emails that you send using the configuration set."
  default     = false
}

variable "email_tracking_redirect_domain" {
  type        = string
  description = "(Required) The domain to use for tracking open and click events."
  default     = null
}

variable "email_tracking_https_policy" {
  type        = string
  description = "The https policy to use for tracking open and click events."
  default     = "OPTIONAL"
}

variable "enable_vdm_options" {
  type        = bool
  description = "An object that defines the VDM settings that apply to emails that you send using the configuration set."
  default     = false
}

variable "vdm_engagement_metrics" {
  type        = string
  description = "Specifies the status of your VDM engagement metrics collection."
  default     = "DISABLED"
}

variable "vdm_optimized_shared_delivery" {
  type        = string
  description = "Specifies the status of your VDM optimized shared delivery."
  default     = "DISABLED"
}

# SESv2 Email Identity
variable "email_identity" {
  type        = string
  description = "The email address or domain to verify."
  default     = null
}

variable "additional_email_identities" {
  type        = list(string)
  description = "List of additional Email-type identities to create. This share the same Configuration Set"
  default     = []
}

variable "enable_identity_policy" {
  type        = bool
  description = "Whether to create SESv2 Identity Policy"
  default     = false
}

variable "identity_policy_json" {
  type        = string
  description = "SESv2 identity policy in JSON format."
  default     = null
}


### Domain identity variables
variable "verify_domain_identity" {
  type        = bool
  description = "Whether to verify `email_identity` or not - used for Domain identity"
  default     = false
}

variable "use_route53_domain" {
  type        = bool
  description = "Whether to use a Route53 domain as SESv2 Domain identity"
  default     = true
}

variable "easy_dkim_key_length" {
  type        = string
  description = "The key length of the future DKIM key pair to be generated. This can be changed at most once per day."
  default     = "RSA_2048_BIT"
}

variable "domain_zone_id" {
  type        = string
  description = "Zone ID for the Domain identity"
  default     = null
}

variable "domain_region" {
  type        = string
  description = "Region for the Domain identity"
  default     = null
}


### Identity MAIL FROM variables
variable "create_mail_from_domain" {
  type        = bool
  description = "Whether to create SESv2 identity custom MAIL FROM domain instead of the default `subdomain of amazonses.com`"
  default     = false
}

variable "mail_from_domain" {
  type        = string
  description = "The custom MAIL FROM domain that you want the verified identity to use."
  default     = null
}

variable "mail_from_failure_behavior" {
  type        = string
  description = "The action to take if the required MX record isn't found when you send an email."
  default     = "USE_DEFAULT_VALUE"
}


### CloudWatch Event Destination variables
variable "events_send_to_cloudwatch" {
  type        = list(string)
  description = "Specifies which events the Amazon SES API v2 should send to the destination"
  default     = ["REJECT", "BOUNCE", "COMPLAINT"]
}


### SNS Event Destination variables
variable "enable_sns_notifications" {
  type        = bool
  description = "Whether send SESv2 events notification to SNS"
  default     = false
}

variable "sns_notification_arns" {
  type        = list(string)
  description = "Existing SNS topic ARNs"
  default     = []
}

variable "events_send_to_sns" {
  type        = list(string)
  description = "Specifies which events the Amazon SES API v2 should send to the destination"
  default     = ["REJECT", "BOUNCE", "COMPLAINT"]
}


### EventBridge Event Destination variables
variable "enable_eventbridge_notifications" {
  type        = bool
  description = "Whether send SESv2 events notification to Event Bus"
  default     = false
}

variable "event_bus_arns" {
  type        = list(string)
  description = "Existing Event Bus topic ARNs"
  default     = []
}

variable "events_send_to_eventbridge" {
  type        = list(string)
  description = "Specifies which events the Amazon SES API v2 should send to the destination"
  default     = ["REJECT", "BOUNCE", "COMPLAINT"]
}


### PinPoint Event Destination variables
variable "enable_pinpoint_notifications" {
  type        = bool
  description = "Whether send SESv2 events notification to PinPoint Applications"
  default     = false
}

variable "pinpoint_application_arns" {
  type        = list(string)
  description = "Existing PinPoint Application ARNs"
  default     = []
}

variable "events_send_to_pinpoint" {
  type        = list(string)
  description = "Specifies which events the Amazon SES API v2 should send to the destination"
  default     = ["REJECT", "BOUNCE", "COMPLAINT"]
}


### Kinesis Firehose Event Destination variables
variable "enable_firehose_notifications" {
  type        = bool
  description = "Whether send SESv2 events notification to Kinesis Firehose"
  default     = false
}

variable "firehose_stream_arns" {
  type        = list(string)
  description = "Existing Kinesis Firehose delivery stream ARNs"
  default     = []
}

variable "firehose_notification_role_arn" {
  type        = string
  description = "ARN of the IAM role that the Amazon SES API v2 uses to send email events to the Amazon Kinesis Data Firehose stream."
  default     = null
}

variable "events_send_to_firehose" {
  type        = list(string)
  description = "Specifies which events the Amazon SES API v2 should send to the destination"
  default     = ["REJECT", "BOUNCE", "COMPLAINT"]
}

