resource "aws_s3_bucket" "django_static" {
  bucket = "django-dev-static-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "django-dev-codepipeline-artifacts-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
