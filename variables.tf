variable "region" {
  description = "Primary AWS region for infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability Zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_subnets" {
  description = "Application subnet CIDRs"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "data_subnets" {
  description = "Database / Data subnet CIDRs"
  type        = list(string)
  default     = ["10.0.5.0/24", "10.0.6.0/24"]
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDS master password (must be >= 8 chars)"
  type        = string
  sensitive   = true
  default     = "StrongP@ssw0rd123"
}

variable "env" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID"
  type        = string
}

variable "domain" {
  description = "Root domain name"
  type        = string
  default     = "ritualroast.online"
}

variable "subdomain" {
  description = "Subdomain for CloudFront / S3 (use @ for root)"
  type        = string
  default     = "www"
}

# NEW — Needed for CloudFront, ACM, and S3 naming
variable "site_bucket_name" {
  description = "Name of the S3 static bucket (without environment)"
  type        = string
  default     = "ritual-roast-static"
}

# Optional: Use this for global CloudFront resources
variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}
