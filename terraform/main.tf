# EFS
# Add EFS security group
resource "aws_security_group" "efs" {
  name        = "factorio-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.instance.id]
  }

  tags = {
    Name = "factorio-efs-sg"
  }
}

# Create EFS file system
resource "aws_efs_file_system" "factorio" {
  creation_token = "factorio-data"
  encrypted      = true

  tags = {
    Name = "factorio-efs"
  }
}

# Create mount target for EFS
resource "aws_efs_mount_target" "factorio" {
  file_system_id  = aws_efs_file_system.factorio.id
  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.efs.id]
}



# EC2 Config
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "factorio-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zone

  map_public_ip_on_launch = true  # Auto-assign public IPs

  tags = {
    Name = "factorio-public-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "factorio-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "factorio-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "instance" {
  name        = "factorio-server-sg"
  description = "Security group for Factorio server"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 34197
    to_port     = 34197
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "factorio-sg"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "factorio" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.large"
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.instance.id]
  
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "factorio-server"
  }

  depends_on = [
    aws_internet_gateway.main,
    aws_efs_mount_target.factorio
    ]
}

# Add EFS DNS name to outputs
output "efs_dns_name" {
  value       = aws_efs_file_system.factorio.dns_name
  description = "EFS DNS name"
}

output "public_ip" {
  value = aws_instance.factorio.public_ip
  description = "Public IP of the Factorio server"
}