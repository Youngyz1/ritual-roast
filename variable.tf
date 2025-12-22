variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Primary domain name"
  type        = string
  default     = "ritualroast.online"
}

# Declare ECR Image URI
variable "ecr_image_uri" {
  description = "URI for the Docker image in ECR"
  type        = string
}
