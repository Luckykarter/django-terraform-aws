resource "aws_ecr_repository" "django_app" {
  name = "django-app-dev"

  image_scanning_configuration {
    scan_on_push = true
  }
}