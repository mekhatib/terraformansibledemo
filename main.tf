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

resource "aws_instance" "example" {
  ami           = "ami-08a0d1e16fc3f61ea" # Replace with your desired AMI ID
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.available.ids[0]
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
    Name = "ExampleInstance"
  }
}