resource "aws_ecs_cluster" "main" {
  name = "django-dev-cluster"
}

resource "aws_cloudwatch_log_group" "django_app" {
  name              = "/ecs/django-app-dev"
  retention_in_days = 7
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "django-dev-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_ecs_task_definition" "django_app" {
  family                   = "django-app-dev"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "django-app"
      image     = "${aws_ecr_repository.django_app.repository_url}:latest"
      essential = true
      secrets   = [
        {
          name      = "DJANGO_SECRET_KEY"
          valueFrom = "${aws_secretsmanager_secret.django_app_secrets.arn}:DJANGO_SECRET_KEY::"
        },
        {
          name      = "DB_USER"
          valueFrom = "${aws_secretsmanager_secret.django_app_secrets.arn}:DB_USER::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.django_app_secrets.arn}:DB_PASSWORD::"
        }
      ]

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "AWS_STORAGE_BUCKET_NAME"
          value = aws_s3_bucket.django_static.bucket
        },
        {
          name  = "AWS_S3_REGION_NAME"
          value = "eu-west-2"
        },
        {
          name  = "DEBUG"
          value = "x"
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.django_app.db_name
        },
        {
          name  = "DB_HOST"
          value = aws_db_instance.django_app.address
        },
        {
          name  = "DB_PORT"
          value = "5432"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          awslogs-group         = aws_cloudwatch_log_group.django_app.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "django"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "django_app" {
  name                   = "django-app-dev-service"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.django_app.arn
  launch_type            = "FARGATE"
  desired_count          = 1
  enable_execute_command = true

  network_configuration {
    subnets = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id
    ]
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.django_app.arn
    container_name   = "django-app"
    container_port   = 8000
  }

}


resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "django-dev-ecs-task-execution-secrets-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.django_app_secrets.arn
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task" {
  name = "django-dev-ecs-task-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_exec" {
  name = "django-dev-ecs-task-exec-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.django_static.arn,
          "${aws_s3_bucket.django_static.arn}/*"
        ]
      }
    ]
  })
}