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

# Data source to get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source to get the subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Use the first subnet ID from the list of default subnets
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.default.ids[0]

  tags = {
    Name = "example-instance"
  }


  provisioner "local-exec" {
    command = "ansible-playbook -i inventory.ini playbook.yml"
  }

}
output "instance_id" {
  value = aws_instance.example.id
}

output "public_ip" {
  value = aws_instance.example.public_ip
}