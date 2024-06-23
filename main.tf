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
  ami           = "ami-08a0d1e16fc3f61ea"
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.default.ids[0]

  tags = {
    Name = "example-instance"
  }

   provisioner "remote-exec" {
    inline = [
      "if [ ! -f /tmp/playbook.yml ]; then",
      "  echo '---' > /tmp/playbook.yml",
      "  echo '- hosts: localhost' >> /tmp/playbook.yml",
      "  echo '  tasks:' >> /tmp/playbook.yml",
      "  echo '    - name: Ensure Apache is installed' >> /tmp/playbook.yml",
      "  echo '      apt:' >> /tmp/playbook.yml",
      "  echo '        name: apache2' >> /tmp/playbook.yml",
      "  echo '        state: present' >> /tmp/playbook.yml",
      "fi",
      "ansible-playbook /tmp/playbook.yml"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu" # Update with your instance's user
      private_key = file("~/.ssh/id_rsa") # Update with your private key path
      host        = self.public_ip
    }
  }

}
output "instance_id" {
  value = aws_instance.example.id
}

output "public_ip" {
  value = aws_instance.example.public_ip
}