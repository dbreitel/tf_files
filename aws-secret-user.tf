# Configure AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Create IAM User
resource "aws_iam_user" "secrets_user" {
  name = "secrets-manager-user"
  
  tags = {
    Description = "User with limited Secrets Manager access"
    Managed_by  = "terraform"
  }
}

# Create access keys for the user
resource "aws_iam_access_key" "secrets_user_key" {
  user = aws_iam_user.secrets_user.name
}

# Create IAM policy for specific secret access
resource "aws_iam_policy" "secret_policy" {
  name        = "specific-secret-access-policy"
  description = "Policy for accessing specific secret in Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecretsManagerListAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowSpecificSecretAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:us-west-2:${data.aws_caller_identity.current.account_id}:secret:mtrx-secret-*"
      }
    ]
  })
}

# Attach the policy to the user
resource "aws_iam_user_policy_attachment" "secret_policy_attach" {
  user       = aws_iam_user.secrets_user.name
  policy_arn = aws_iam_policy.secret_policy.arn
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Output the access keys (be careful with these!)
output "access_key_id" {
  value = aws_iam_access_key.secrets_user_key.id
}

output "secret_access_key" {
  value     = aws_iam_access_key.secrets_user_key.secret
  sensitive = true
}

# Output the user ARN
output "user_arn" {
  value = aws_iam_user.secrets_user.arn
}
