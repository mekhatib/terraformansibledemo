terraform {
  required_providers {
    aap = {
      source = "ansible/aap"
    }
    awx = {
      source = "denouche/awx"
      version = "0.27.0"
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

##################awx needed to create credential##################
provider "awx" {
    hostname = "https://aap.onmi.cloud:8443"
    username = "mahil"
    password = var.tower_password
}
###################################################################


# Existing AAP inventory resource
resource "aap_inventory" "my_inventory" {
  name         = "TF Inventory"
  description  = "A new inventory for testing"
  organization = 2
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
ingress {
    from_port   = 80
    to_port     = 80
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
  ami           = "ami-04b70fa74e45c3917" # Replace with your preferred AMI
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name
  subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              # Commands to initialize your instance
              touch /var/tmp/instance_ready
              EOF

  tags = {
    Name = "Demo-instance"

  }
}

##############sleep for 30 seconds to allow instance to be ready##################

# This resource will destroy (potentially immediately) after null_resource.next

resource "time_sleep" "wait_30_seconds" {
  depends_on = [aws_instance.example]

  create_duration = "30s"
}

# This resource will create (at least) 30 seconds after null_resource.previous
resource "null_resource" "next" {
  depends_on = [time_sleep.wait_30_seconds]
}


##################awx needed to create credential##################

resource "awx_credential_machine" "example" {
  name        = "Terraform Generated Key"
  description = "SSH Private Key generated by Terraform"
  organization_id = 2
  username = "ubuntu"
  ssh_key_data = tls_private_key.example.private_key_pem
  
}

resource "awx_job_template" "baseconfig" {
  name           = "Base Service Configuration"
  job_type       = "run"
  inventory_id   = aap_inventory.my_inventory.id
  project_id     = "14"
  #playbook       = "install_jenkins.yaml" # jenkins playbook
  playbook       = "install_nginx.yml" # nginx playbook
  become_enabled = true

depends_on = [aap_host.example_host]

}

resource "awx_job_template_credential" "baseconfig" {
  job_template_id = awx_job_template.baseconfig.id
  credential_id   = awx_credential_machine.example.id

  depends_on = [aws_instance.example]
}

###################################################################

# Add the EC2 instance's IP to the AAP inventory
resource "aap_host" "example_host" {
  name        = "EC2Instance-${aws_instance.example.id}"
  description = "Host created from EC2 instance"
  inventory_id   = aap_inventory.my_inventory.id
  variables   = jsonencode({
    "ansible_host": aws_instance.example.public_ip
  })
}

#JOB KICKOFF
resource "aap_job" "example_job" {
   job_template_id = awx_job_template.baseconfig.id
   inventory_id    = aap_inventory.my_inventory.id
  

   depends_on = [time_sleep.wait_30_seconds]
}


output "instance_public_ip" {
  value = aws_instance.example.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}