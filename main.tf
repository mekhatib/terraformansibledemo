terraform {
  required_providers {
   

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8.0"
    }

   
  }

}
# main.tf

provider "aws" {
  region = var.region
}

# Fetch the first available VPC
data "aws_vpcs" "available" {}

# Fetch the first available subnet in the VPC
data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpcs.available.ids[0]]
  }
}

# Create a security group to allow inbound SSH traffic
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow inbound SSH traffic"
  vpc_id      = data.aws_vpcs.available.ids[0]

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
  ami           = "ami-08a0d1e16fc3f61ea" # Replace with your desired AMI ID
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.available.ids[0]
  security_groups = [aws_security_group.allow_ssh.name]
  key_name = var.ssh_key_name

  provisioner "remote-exec" {
    inline = [
      "echo Hello, World!"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = var.ssh_private_key
      host        = self.public_ip
    }
  }

  tags = {
    Name = "MahilInstance"
  }
}