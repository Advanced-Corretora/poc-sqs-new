resource "aws_ecr_repository" "ecr" {
  name = "${var.env}-${var.service_name}-ecr"
  force_delete = true
  tags = {
    Department = var.department
    Environment = var.env
  }
}

resource "aws_ecr_lifecycle_policy" "delete_policy" {
  repository = aws_ecr_repository.ecr.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 30 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 30
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}