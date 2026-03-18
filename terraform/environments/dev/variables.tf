variable "aws_region" {
  type        = string
  description = "The region to deploy resources into"
}

variable "discord_webhook_url" {
  type        = string
  description = "The Discord webhook for alerts"
  sensitive   = true
}