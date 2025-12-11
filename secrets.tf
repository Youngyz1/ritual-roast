# generate a stable suffix to avoid name collisions
resource "random_id" "secret_suffix" {
  byte_length = 4
}

# generate a secure DB password (RDS-friendly)
resource "random_password" "db_password" {
  length           = 20
  override_special = "_-!#%*"
  # ensures no forbidden characters such as '/', '@', '"' or space
}

# create secret with unique name (env + suffix)
resource "aws_secretsmanager_secret" "db" {
  name        = "ritual-roast-db-credentials-${var.env}-${random_id.secret_suffix.hex}"
  description = "RDS credentials for ritual-roast (${var.env})"
  tags = {
    Project = "ritual-roast"
    Env     = var.env
  }
}

resource "aws_secretsmanager_secret_version" "db_version" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

output "secretsmanager_db_secret_arn" {
  value       = aws_secretsmanager_secret.db.arn
  description = "ARN of the new Secrets Manager secret"
}
