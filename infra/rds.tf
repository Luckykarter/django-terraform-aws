locals {
  django_app_secrets = jsondecode(data.aws_secretsmanager_secret_version.django_app_secrets_current.secret_string)
}

resource "aws_db_subnet_group" "django_app" {
  name = "django-dev-db-subnet-group"

  subnet_ids = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "django-dev-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "django-dev-rds-sg"
  description = "Allow PostgreSQL access from ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "django-dev-rds-sg"
  }
}

resource "aws_db_instance" "django_app" {
  identifier = "django-dev-postgres"

  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "django"
  username = local.django_app_secrets.DB_USER
  password = local.django_app_secrets.DB_PASSWORD

  db_subnet_group_name   = aws_db_subnet_group.django_app.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  skip_final_snapshot = true

  backup_retention_period = 1
  deletion_protection     = false

  tags = {
    Name = "django-dev-postgres"
  }
}