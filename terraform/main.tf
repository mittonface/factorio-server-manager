provider "aws" {
  region = "us-east-1"  # Changed to match your secret's region
}

data "aws_ecr_repository" "factorio" {
  name = "bm-factorio-image"
}


# VPC and Network Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "factorio-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"  # Changed to match region

  tags = {
    Name = "factorio-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "factorio-igw"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "factorio-route-table"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Security Group
resource "aws_security_group" "factorio" {
  name        = "factorio-server"
  description = "Security group for Factorio server"
  vpc_id      = aws_vpc.main.id

  # Game traffic and server listing (UDP + TCP)
  ingress {
    from_port   = 34197
    to_port     = 34197
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Factorio game port (UDP)"
  }

  ingress {
    from_port   = 34197
    to_port     = 34197
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Factorio server listing port (TCP)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "factorio-cluster"
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "factorio-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Add policy to allow reading from Secrets Manager
resource "aws_iam_role_policy" "secrets_policy" {
  name = "factorio-secrets-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:us-east-1:009960124252:secret:factorio-server-credentials-0vrhaq"
        ]
      }
    ]
  })
}

# Create CloudWatch Log Group
resource "aws_cloudwatch_log_group" "factorio" {
  name              = "/ecs/factorio"
  retention_in_days = 30  # Adjust retention period as needed
}

# Add logging permissions to the task execution role
resource "aws_iam_role_policy" "cloudwatch_logs_policy" {
  name = "factorio-cloudwatch-logs-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.factorio.arn}:*"
      }
    ]
  })
}


# ECS Task Definition
resource "aws_ecs_task_definition" "factorio" {
  family                   = "factorio"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = "1024"
  memory                  = "2048"
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "factorio"
      image = "${data.aws_ecr_repository.factorio.repository_url}:latest"
      portMappings = [
        {
          containerPort = 34197
          hostPort      = 34197
          protocol      = "udp"
        },
        {
          containerPort = 27015
          hostPort      = 27015
          protocol      = "tcp"
        }
      ]
      essential = true
      environment = [
        {
          name  = "GENERATE_NEW_SAVE"
          value = "true"
        },
        {
            name = "SAVE_NAME",
            value="boygonewild"
        },
        {
          name  = "SERVER_NAME"
          value = "Server for Pretty Special Boys"
        }
      ]
      secrets = [
        {
          name = "USERNAME"
          valueFrom = "arn:aws:secretsmanager:us-east-1:009960124252:secret:factorio-server-credentials-0vrhaq:FACTORIO_USERNAME::"
        },
        {
          name = "FACTORIO_PASSWORD"
          valueFrom = "arn:aws:secretsmanager:us-east-1:009960124252:secret:factorio-server-credentials-0vrhaq:FACTORIO_PASSWORD::"
        },

        {
          name = "SERVER_PASSWORD"
          valueFrom = "arn:aws:secretsmanager:us-east-1:009960124252:secret:factorio-server-credentials-0vrhaq:GAME_PASSWORD::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.factorio.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "factorio" {
  name            = "factorio"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.factorio.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.main.id]
    security_groups  = [aws_security_group.factorio.id]
    assign_public_ip = true
  }
}

# Output the public IP
output "public_ip" {
  value = aws_ecs_service.factorio.network_configuration[0].assign_public_ip
  description = "Public IP of the Factorio server"
}