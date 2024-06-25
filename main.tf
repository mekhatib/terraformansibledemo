terraform {
  required_providers {
    aap = {
      source = "ansible/aap"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


provider "aap" {
  host                 = "https://aap.onmi.cloud:8443"
  username             = "mahil"
  password             = var.tower_password
  insecure_skip_verify = true
}

resource "aap_inventory" "mahil_inventory" {
  name         = "Mahil TF Inventory"
  description  = "A new inventory for testing"
  organization = 2
}

# Add the EC2 instance's IP to the AAP inventory
resource "aap_host" "example_host" {
  name        = "EC2Instance-${aws_instance.example.id}"
  description = "Host created from EC2 instance"
  inventory_id   = aap_inventory.mahil_inventory.id
  variables   = jsonencode({
    "ansible_host": aws_instance.example.public_ip
  })
}


resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "generated-key"
  public_key = tls_private_key.example.public_key_openssh
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "instance" {
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

resource "aws_instance" "example" {
  ami           = "ami-08a0d1e16fc3f61ea" # Replace with your preferred AMI
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name
  #subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  associate_public_ip_address = true

  tags = {
    Name = "Demo-instance"
  }
}


output "instance_public_ip" {
  value = aws_instance.example.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}