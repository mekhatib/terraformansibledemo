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
}



resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "t2.micro"

  tags = {
    Name = "Terraform-Ansible-Demo"
  }
}

output "instance_ip" {
  value = aws_instance.example.public_ip
}