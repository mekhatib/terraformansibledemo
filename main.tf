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

resource "aws_instance" "example" {
  ami           = "ami-07f92c21ece77c17d" # Replace with your desired AMI ID
  instance_type = "t2.micro"

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