resource "aws_ecr_repository" "bookstore" {
  name                 = var.project_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = {
    Project     = var.project_name
    Description = "BookStore application Docker images"
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.bookstore.repository_url
}
