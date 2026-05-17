output "django_static_bucket_name" {
  value = aws_s3_bucket.django_static.bucket
}

output "django_static_bucket_arn" {
  value = aws_s3_bucket.django_static.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.django_app.repository_url
}

output "codepipeline_artifacts_bucket_name" {
  value = aws_s3_bucket.codepipeline_artifacts.bucket
}

output "alb_dns_name" {
  value = aws_lb.django_app.dns_name
}

output "django_app_secrets_arn" {
  value = aws_secretsmanager_secret.django_app_secrets.arn
}

output "rds_endpoint" {
  value = aws_db_instance.django_app.address
}