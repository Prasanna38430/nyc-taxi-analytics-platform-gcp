# Notification channels for alerts

# Email notification channel
resource "google_monitoring_notification_channel" "email" {
  display_name = "NYC Taxi Pipeline - Email Notifications"
  type         = "email"

  labels = {
    email_address = "prasannakumaradabala20@gmail.com"
  }

  enabled = true
}

# MS Teams notification channel via Webhook
resource "google_monitoring_notification_channel" "ms_teams" {
  display_name = "NYC Taxi Pipeline - MS Teams"
  type         = "slack"

  labels = {
    channel_name = "#pipeline-alerts"
  }

  user_labels = {
    severity = "critical"
  }

  sensitive_labels {
    auth_token = "xoxb-placeholder" # Will use Teams webhook URL in practice
  }

  enabled = true
}

# Alternative: Direct Teams Webhook (using generic webhook)
resource "google_monitoring_notification_channel" "teams_webhook" {
  display_name = "NYC Taxi Pipeline - Teams Webhook"
  type         = "webhook_basic"

  labels = {
    url = "https://epitafr.webhook.office.com/webhookb2/74a8ef7d-9051-4d8a-a467-9d35266e278c@3534b3d7-316c-4bc9-9ede-605c860f49d2/IncomingWebhook/4914e7ff558e44c49cd5c891dd942be0/5901e7ec-ed9d-4b7a-8f38-03530b1dfe0a/V2FLXD8kbqWhuGpI9kwmUgZMQUFIe7aadL3z5_VYMCKqY1"
  }

  enabled = true
}
