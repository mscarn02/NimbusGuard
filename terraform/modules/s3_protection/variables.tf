variable "aws_region" {
	description = "The AWS region to deploy to"
	type		= string
	default		= "us-east-1"
}

variable "discord_webhook_url" {
	description = "The URL for Discord alerts"
	type		= string
	sensitive	= true
}