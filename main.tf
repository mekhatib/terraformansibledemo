provider "aws" {
  region = "us-east-1"
}

provider "tower" {
  host     = "https://aap.onmi.cloud:8443"
  username = "mahil"
  password = "Magrebis1977$"
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

resource "tower_project" "example" {
  name      = "Example Project"
  scm_type  = "git"
  scm_url   = "https://github.com/mekhatib/ansibledemo.git"
  scm_branch = "main"
}

resource "tower_inventory" "example" {
  name = "Example Inventory"
}

resource "tower_credential" "example" {
  name     = "Example Credential"
  kind     = "ssh"
  username = "ec2-user"
  ssh_key_data = tls_private_key.example.private_key_pem
}

resource "tower_job_template" "nginx_install" {
  name          = "Install NGINX"
  inventory_id  = tower_inventory.example.id
  project_id    = tower_project.example.id
  playbook      = "install_nginx.yml"
  credential_id = tower_credential.example.id
}

resource "tower_job_launch" "nginx_install" {
  job_template_id = tower_job_template.nginx_install.id
  extra_vars = jsonencode({
    ansible_host = aws_instance.example.public_ip
  })
}

output "instance_public_ip" {
  value = aws_instance.example.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}