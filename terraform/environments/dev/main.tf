terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

output "account_id" {
	value = data.aws_caller_identity.current.account_id
}

module "s3_protection" {
  source              = "../../modules/s3_protection"
  discord_webhook_url = var.discord_webhook_url
}

module "sg_protection" {
  source              = "../../modules/sg_protection"
  discord_webhook_url = var.discord_webhook_url
}