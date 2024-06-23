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

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0" # Change to your desired AMI
  instance_type = "t2.micro"
  subnet_id     = data.aws_vpc.default.default_network_acl_id

  tags = {
    Name = "WebServer"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i inventory.ini playbook.yml"
  }
}

output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
