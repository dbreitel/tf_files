# Configure AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Create the AWS Secrets Manager secret
resource "aws_secretsmanager_secret" "mtrx_secret" {
  name = "mtrx-secret"
  
  # Optional: Add tags for better resource management
  tags = {
    Environment = "production"
    Managed_by  = "terraform"
  }
}

# Create an initial version of the secret (optional)
resource "aws_secretsmanager_secret_version" "mtrx_secret_version" {
  secret_id = aws_secretsmanager_secret.mtrx_secret.id
  
  # You can specify your secret value here
  # Be careful not to commit sensitive values directly in the code
  # Consider using variables or separate terraform.tfvars file
  secret_string = jsonencode({
    "key1" : "value1",
    "key2" : "value2"
  })
}

# Output the secret ARN for reference
output "secret_arn" {
  value = aws_secretsmanager_secret.mtrx_secret.arn
}
