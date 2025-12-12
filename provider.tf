# ==========================================================
# Provider
# ==========================================================
provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}


