# 🛡️ Nimbus: Event-Driven Cloud Security Remediation

## Overview
Nimbus is a serverless, automated cloud security control plane built on AWS. Designed to shift security from reactive monitoring to proactive engineering, this framework detects critical infrastructure misconfigurations in real-time and automatically executes self-healing remediation logic before threat actors can exploit them.

## Core Architecture
The system utilizes an event-driven architecture to ensure remediations occur within seconds of a violation:
1. **Detection:** AWS CloudTrail captures management events (API calls).
2. **Routing:** Amazon EventBridge filters for specific high-risk API signatures.
3. **Execution:** AWS Lambda (Python/Boto3) executes targeted remediation logic using the Principle of Least Privilege.
4. **Notification:** Webhook integration pushes structured incident reports to out-of-band communication channels (Discord/Slack).
5. **Infrastructure as Code:** The entire stack is deployed and managed via Terraform for version-controlled, repeatable environments.

## Active Guardrails (Modules)

### 1. S3 Public Access Lockdown (`s3_protection`)
* **Trigger:** `CreateBucket` API call.
* **Risk:** Data exfiltration via accidentally exposed object storage.
* **Remediation:** Boto3 injects a `PutPublicAccessBlock` configuration, forcing all public access blocks to `True` regardless of user input.

### 2. EC2 Security Group Ingress Sanitization (`sg_protection`)
* **Trigger:** `AuthorizeSecurityGroupIngress` API call.
* **Risk:** Botnet compromise via open management ports (SSH/RDP).
* **Remediation:** Parses the nested IP permissions; if Port 22 or 3389 is exposed to `0.0.0.0/0`, the Lambda surgically revokes that specific rule while leaving legitimate application traffic intact.

## Technology Stack
* **Cloud Provider:** Amazon Web Services (AWS)
* **Compute:** AWS Lambda (Serverless)
* **Event Router:** Amazon EventBridge
* **Audit Logging:** AWS CloudTrail
* **Automation Logic:** Python 3.12, Boto3 SDK
* **IaC:** Terraform (HCL)

## Deployment Instructions
*(Requires AWS CLI configured with appropriate IAM permissions)*
1. Clone the repository.
2. Navigate to `terraform/environments/dev/`.
3. Create a `terraform.tfvars` file and define your `discord_webhook_url`.
4. Run `terraform init` to download providers.
5. Run `terraform apply` to provision the infrastructure.