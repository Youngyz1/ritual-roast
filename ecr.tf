# =========================
# ECR Repository
# =========================
resource "aws_ecr_repository" "ritual_roast" {
  name                 = "ritual-roast"
  image_tag_mutability = "MUTABLE" # Change to "IMMUTABLE" if you don't want tags overwritten
  force_delete         = true      # Allows repository deletion even with images

  image_scanning_configuration {
    scan_on_push = true # Scan images on push for vulnerabilities
  }

  tags = {
    Name = "ritual-roast"
    App  = "ritual-roast"
  }

  lifecycle {
    prevent_destroy = false  # Allow destroy
    ignore_changes  = [tags] # Ignore changes to tags, e.g., if managed externally
  }
}

#=================================================
# ECR Lifecycle Policy
#=================================================
resource "aws_ecr_lifecycle_policy" "ritual_roast_policy" {
  repository = aws_ecr_repository.ritual_roast.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire" # Expire older images than the limit
        }
      }
    ]
  })

  lifecycle {
    prevent_destroy = false    # Allow destroy
    ignore_changes  = [policy] # Ignore changes to policy, useful if updated externally
  }

  depends_on = [
    aws_ecr_repository.ritual_roast # Ensure the repository is created before the policy
  ]
}
