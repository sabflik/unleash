# ECS Cluster for Fargate tasks
resource "aws_ecs_cluster" "main" {
  for_each = var.regions
  region   = each.key
  name     = "compute-cluster-${each.key}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Region = each.key
  }
}

# CloudWatch Log Group for ECS tasks
resource "aws_cloudwatch_log_group" "ecs_logs" {
  for_each          = var.regions
  region            = each.key
  name              = "/ecs/compute-${each.key}"
  retention_in_days = 7

  tags = {
    Region = each.key
  }
}

# IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "dispatch_ecs_policy" {
  name = "dispatch-ecs-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "SNS:Publish",
        ]
        Effect   = "Allow"
        Resource = var.sns_topic_arn
      }
    ]
  })
}

# Attach the default ECS task execution policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM role for the ECS task itself
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Security group for ECS tasks in public subnet
resource "aws_security_group" "ecs_tasks" {
  for_each    = var.regions
  region      = each.key
  name        = "ecs-tasks-sg-${each.key}"
  description = "Security group for ECS tasks in ${each.key}"
  vpc_id      = aws_vpc.main[each.key].id

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

  tags = {
    Region = each.key
  }
}

# ECS Task Definition for Fargate
resource "aws_ecs_task_definition" "app" {
  for_each                 = var.regions
  region                   = each.key
  family                   = "compute-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "publish-app"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs[each.key].name
          "awslogs-region"        = each.key
          "awslogs-stream-prefix" = "ecs"
        }
      }
      command = [
        "sns",
        "publish",
        "--topic-arn",
        var.sns_topic_arn,
        "--message",
        "{\"email\": \"sabflik@hotmail.com\",\"source\": \"ECS\", \"region\": \"$AWS_REGION\", \"repo\":\"https://github.com/sabflik/unleash\"}"
      ]
    }
  ])
}

# ECS Service for Fargate tasks in public subnet
resource "aws_ecs_service" "app" {
  for_each            = var.regions
  region              = each.key
  name                = "compute-service-${each.key}"
  cluster             = aws_ecs_cluster.main[each.key].id
  task_definition     = aws_ecs_task_definition.app[each.key].arn
  desired_count       = var.ecs_desired_count
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"

  network_configuration {
    subnets          = [aws_subnet.public[each.key].id]
    security_groups  = [aws_security_group.ecs_tasks[each.key].id]
    assign_public_ip = true
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_role_policy]
}
