provider "aws" {
  region = "us-east-1"
}

# Generate SSH key pair
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the private key to a local file
resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/private_key.pem"
  file_permission = "0600"
}

# Save the public key to a local file
resource "local_file" "public_key" {
  content  = tls_private_key.example.public_key_openssh
  filename = "${path.module}/public_key.pub"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Subnet
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Route Table Association
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Security Group
resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
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

# EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-08a0d1e16fc3f61ea" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main.id
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.main.id]

  tags = {
    Name = "TerraformExample"
  }
}

# Elastic IP
resource "aws_eip" "web" {
  instance = aws_instance.web.id
}

# Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = tls_private_key.example.public_key_openssh
}

output "instance_ip" {
  value = aws_eip.web.public_ip
}

output "private_key_path" {
  value = local_file.private_key.filename
}