##################################
# VARIABLES REQUIRED
##################################
# vpc_id
# public_subnets
# private_subnets
# frontend_container_image
# backend_container_image
# db_private_ip
# frontend_cert_arn
# backend_cert_arn

##################################
# ALB SECURITY GROUP
##################################
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##################################
# APPLICATION LOAD BALANCER
##################################
resource "aws_lb" "this" {
  name               = "main-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]
}

##################################
# HTTP → HTTPS REDIRECT
##################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

##################################
# HTTPS LISTENER (SNI)
##################################
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.frontend_cert_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      status_code  = 404
      content_type = "text/plain"
      message_body = "Not Found"
    }
  }
}

resource "aws_lb_listener_certificate" "backend_cert" {
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = var.backend_cert_arn
}

##################################
# TARGET GROUPS
##################################
resource "aws_lb_target_group" "frontend_tg" {
  name        = "frontend-ecs-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "backend-ecs-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/health"
    matcher = "200"
  }
}

##################################
# LISTENER RULES
##################################
resource "aws_lb_listener_rule" "frontend_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  condition {
    host_header {
      values = ["madeep.shop"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 20

  condition {
    host_header {
      values = ["backend.madeep.shop"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

##################################
# ECS CLUSTER
##################################
resource "aws_ecs_cluster" "this" {
  name = "ecs-fargate-cluster"
}

##################################
# ECS IAM ROLE
##################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

##################################
# ECS SECURITY GROUPS
##################################
resource "aws_security_group" "frontend_sg" {
  name   = "ecs-frontend-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend_sg" {
  name   = "ecs-backend-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##################################
# ECS TASK DEFINITIONS
##################################
resource "aws_ecs_task_definition" "backend" {
  family                   = "backend-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "backend"
    image     = var.backend_container_image
    essential = true
    portMappings = [{ containerPort = 5000 }]
    environment = [{ name = "MONGO_HOST", value = var.db_private_ip }]
  }])
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "frontend"
    image     = var.frontend_container_image
    essential = true
    portMappings = [{ containerPort = 80 }]
  }])
}

##################################
# ECS SERVICES
##################################
resource "aws_ecs_service" "backend" {
  name            = "backend-ecs-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.backend_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend"
    container_port   = 5000
  }
}

resource "aws_ecs_service" "frontend" {
  name            = "frontend-ecs-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.frontend_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend"
    container_port   = 80
  }
}
