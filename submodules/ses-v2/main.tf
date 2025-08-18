data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
locals {
  email_identity_name = replace(replace(var.email_identity, ".", "-"), "@", "-")
}


# Configuration set
resource "aws_sesv2_configuration_set" "identity" {
  configuration_set_name = local.email_identity_name
  delivery_options {
    max_delivery_seconds = var.delivery_max_seconds
    tls_policy           = var.delivery_tls_policy
    sending_pool_name    = var.delivery_sending_pool_name
  }
  reputation_options {
    reputation_metrics_enabled = var.enable_reputation_metrics
  }
  sending_options {
    sending_enabled = var.enable_email_sending
  }
  suppression_options {
    suppressed_reasons = var.append_suppression_list_on
  }

  dynamic "tracking_options" {
    for_each = var.enable_email_tracking != false ? [1] : []
    content {
      custom_redirect_domain = var.email_tracking_redirect_domain
      https_policy           = var.email_tracking_https_policy
    }
  }

  dynamic "vdm_options" {
    for_each = var.enable_vdm_options != false ? [1] : []
    content {
      dashboard_options {
        engagement_metrics = var.vdm_engagement_metrics
      }
      guardian_options {
        optimized_shared_delivery = var.vdm_optimized_shared_delivery
      }
    }
  }
  tags = var.tags
}


# Create new SES Identity (email or domain)
resource "aws_sesv2_email_identity" "identity" {
  email_identity         = var.email_identity
  configuration_set_name = aws_sesv2_configuration_set.identity.configuration_set_name
  dynamic "dkim_signing_attributes" {
    for_each = var.verify_domain_identity ? [1] : []
    content {
      next_signing_key_length = var.easy_dkim_key_length
    }
  }
  tags = var.tags
}


# Notifications > Email feedback forwarding
resource "aws_sesv2_email_identity_feedback_attributes" "identity" {
  email_identity           = aws_sesv2_email_identity.identity.email_identity
  email_forwarding_enabled = true
}


# SESv2 Email Identity policy
resource "aws_sesv2_email_identity_policy" "identity" {
  count          = var.enable_identity_policy ? 1 : 0
  email_identity = aws_sesv2_email_identity.identity.email_identity
  policy_name    = local.email_identity_name
  policy         = var.identity_policy_json
}


# Authentication > DomainKeys Identified Mail (DKIM)
# In SESv2, the Domain Verification process has been simplified. 
# You no longer need to create a separate TXT record for domain verification. 
# The DKIM records (3 CNAME records) are sufficient for both verification and DKIM signing.
resource "aws_route53_record" "dkim_record" {
  count   = var.verify_domain_identity && var.use_route53_domain ? 3 : 0
  zone_id = var.domain_zone_id
  name    = "${element(aws_sesv2_email_identity.identity.dkim_signing_attributes[0].tokens, count.index)}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_sesv2_email_identity.identity.dkim_signing_attributes[0].tokens, count.index)}.dkim.amazonses.com"]
}


# Authentication > Custom MAIL FROM domain 
resource "aws_sesv2_email_identity_mail_from_attributes" "identity" {
  count                  = var.create_mail_from_domain ? 1 : 0
  email_identity         = aws_sesv2_email_identity.identity.email_identity
  behavior_on_mx_failure = var.mail_from_failure_behavior
  mail_from_domain       = var.verify_domain_identity ? (var.use_route53_domain ? "bounce.${aws_sesv2_email_identity.identity.email_identity}" : var.mail_from_domain) : var.mail_from_domain
}


# MX record to publish to the DNS server of the custom MAIL FROM domain
resource "aws_route53_record" "ses_domain_mail_from_mx" {
  count   = var.create_mail_from_domain && var.use_route53_domain ? 1 : 0
  zone_id = var.domain_zone_id
  name    = aws_sesv2_email_identity_mail_from_attributes.identity[0].mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${var.domain_region}.amazonses.com"]
}


# SPF (type TXT) record to publish to the DNS server of the custom MAIL FROM domain
resource "aws_route53_record" "ses_domain_mail_from_txt" {
  count   = var.create_mail_from_domain && var.use_route53_domain ? 1 : 0
  zone_id = var.domain_zone_id
  name    = aws_sesv2_email_identity_mail_from_attributes.identity[0].mail_from_domain
  type    = "TXT"
  ttl     = "300"
  records = ["v=spf1 include:amazonses.com ~all"]
}


# SES CloudWatch destination
resource "aws_sesv2_configuration_set_event_destination" "cw" {
  configuration_set_name = aws_sesv2_configuration_set.identity.configuration_set_name
  event_destination_name = "cloudwatch-event-destination"

  event_destination {
    enabled              = true
    matching_event_types = var.events_send_to_cloudwatch

    cloud_watch_destination {
      dimension_configuration {
        default_dimension_value = "Unknown"
        dimension_name          = "ses:configuration-set"
        dimension_value_source  = "MESSAGE_TAG"
      }
    }
  }
}


# SES SNS destination
resource "aws_sesv2_configuration_set_event_destination" "sns" {
  count                  = var.enable_sns_notifications ? length(var.sns_notification_arns) : 0
  configuration_set_name = aws_sesv2_configuration_set.identity.configuration_set_name
  event_destination_name = "sns-event-destination-${count.index}"

  event_destination {
    enabled              = true
    matching_event_types = var.events_send_to_sns

    sns_destination {
      topic_arn = var.sns_notification_arns[count.index]
    }
  }
}


# SES EventBridge destination
resource "aws_sesv2_configuration_set_event_destination" "bus" {
  count                  = var.enable_eventbridge_notifications ? length(var.event_bus_arns) : 0
  configuration_set_name = aws_sesv2_configuration_set.identity.configuration_set_name
  event_destination_name = "eventbridge-event-destination-${count.index}"

  event_destination {
    enabled              = true
    matching_event_types = var.events_send_to_eventbridge

    event_bridge_destination {
      event_bus_arn = var.event_bus_arns[count.index]
    }
  }
}


# SES PinPoint destination
resource "aws_sesv2_configuration_set_event_destination" "pinpoint" {
  count                  = var.enable_pinpoint_notifications ? length(var.pinpoint_application_arns) : 0
  configuration_set_name = aws_sesv2_configuration_set.identity.configuration_set_name
  event_destination_name = "pinpoint-event-destination-${count.index}"

  event_destination {
    enabled              = true
    matching_event_types = var.events_send_to_pinpoint

    pinpoint_destination {
      application_arn = var.pinpoint_application_arns[count.index]
    }
  }
}


# SES Kinesis Firehose destination
resource "aws_sesv2_configuration_set_event_destination" "firehose" {
  count                  = var.enable_firehose_notifications ? length(var.firehose_stream_arns) : 0
  configuration_set_name = aws_sesv2_configuration_set.identity.configuration_set_name
  event_destination_name = "firehose-event-destination-${count.index}"

  event_destination {
    enabled              = true
    matching_event_types = var.events_send_to_firehose

    kinesis_firehose_destination {
      delivery_stream_arn = var.firehose_stream_arns[count.index]
      iam_role_arn        = var.firehose_notification_role_arn
    }
  }
}


# Additional SES email identities
resource "aws_sesv2_email_identity" "additional" {
  count                  = var.additional_email_identities != [] ? length(var.additional_email_identities) : 0
  email_identity         = element(var.additional_email_identities, count.index)
  configuration_set_name = aws_sesv2_configuration_set.identity.configuration_set_name
  tags                   = var.tags
}

# Notifications > Email feedback forwarding
resource "aws_sesv2_email_identity_feedback_attributes" "additional" {
  count                    = var.additional_email_identities != [] ? length(var.additional_email_identities) : 0
  email_identity           = aws_sesv2_email_identity.additional[count.index].email_identity
  email_forwarding_enabled = true
}
