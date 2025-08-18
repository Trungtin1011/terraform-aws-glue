output "configuration_set_name" {
  description = "SESv2 configuration set name"
  value       = aws_sesv2_configuration_set.identity.configuration_set_name
}

output "configuration_set_arn" {
  description = "SESv2 configuration set ARN"
  value       = aws_sesv2_configuration_set.identity.arn
}

output "sesv2_reputation_option" {
  description = "Whether or not Amazon SESv2 collects reputation metrics for the emails."
  value       = aws_sesv2_configuration_set.identity.reputation_options[0].reputation_metrics_enabled
}

output "identity_type" {
  description = "SESv2 identity type (DOMAIN or EMAIL_ADDRESS)"
  value       = aws_sesv2_email_identity.identity.identity_type
}

output "identity_arn" {
  description = "SESv2 identity ARN"
  value       = aws_sesv2_email_identity.identity.arn
}

output "identity_dkim_signing_status" {
  description = "SESv2 Domain identity DKIM signing Status"
  value       = try(aws_sesv2_email_identity.identity.dkim_signing_attributes[0].status, "")
}

output "identity_dkim_signing_origin" {
  description = "SESv2 Domain identity DKIM signing Origin (AWS_SES or EXTERNAL)"
  value       = try(aws_sesv2_email_identity.identity.dkim_signing_attributes[0].signing_attributes_origin, "")
}

output "identity_verified_for_sending_status" {
  description = "SESv2 identity sending verification status"
  value       = aws_sesv2_email_identity.identity.verified_for_sending_status
}


