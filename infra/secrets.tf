resource "aws_secretsmanager_secret" "django_app_secrets" {
  name        = "django/dev/app-secrets"
  description = "Application secrets for Django dev ECS deployment"
}

data "aws_secretsmanager_secret_version" "django_app_secrets_current" {
  secret_id = aws_secretsmanager_secret.django_app_secrets.id
}