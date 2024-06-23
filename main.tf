terraform {
  required_providers {
   

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8.0"
    }

   
  }

}

provider "aws" {
  region     = var.region
  profile = "default"
}

resource "aws_instance" "example" {
  ami           = "ami-04b70fa74e45c3917" # Amazon Linux 2 AMI
  instance_type = "t2.micro"

  tags = {
    Name = "Terraform-Ansible-Demo"
  }
}

output "instance_ip" {
  value = aws_instance.example.public_ip
}