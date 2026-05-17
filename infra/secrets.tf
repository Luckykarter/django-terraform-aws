resource "aws_secretsmanager_secret" "django_app_secrets" {
  name        = "django/dev/app-secrets"
  description = "Application secrets for Django dev ECS deployment"
}