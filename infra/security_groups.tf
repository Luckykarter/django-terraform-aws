
resource "aws_security_group" "ecs_service" {
  name        = "django-dev-ecs-service-sg"
  description = "Allow HTTP access to Django ECS task"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Django HTTP from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }


  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "django-dev-ecs-service-sg"
  }
}

resource "aws_security_group" "alb" {
  name        = "django-dev-alb-sg"
  description = "Allow HTTP access to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "django-dev-alb-sg"
  }
}
