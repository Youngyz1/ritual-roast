# --------------------------------------------------------
# Generate a stable suffix to avoid name collisions
# --------------------------------------------------------
resource "random_id" "secret_suffix" {
  byte_length = 4
}

# --------------------------------------------------------
# Generate a secure DB password (RDS-friendly)
# --------------------------------------------------------
resource "random_password" "db_password" {
  length           = 20
  override_special = "_-!#%*"
  # avoids forbidden characters such as '/', '@', '"' or space
}

# --------------------------------------------------------
# Create Secrets Manager secret with unique name
# --------------------------------------------------------
resource "aws_secretsmanager_secret" "db" {
  name        = "ritual-roast-db-credentials-${var.env}-${random_id.secret_suffix.hex}"
  description = "RDS credentials for ritual-roast (${var.env})"

  tags = {
    Project = "ritual-roast"
    Env     = var.env
  }
}

# --------------------------------------------------------
# Store secret version (username + password)
# --------------------------------------------------------
resource "aws_secretsmanager_secret_version" "db_version" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

# --------------------------------------------------------
# Output the Secret ARN
# --------------------------------------------------------
output "secretsmanager_db_secret_arn" {
  value       = aws_secretsmanager_secret.db.arn
  description = "ARN of the new Secrets Manager secret"
}
