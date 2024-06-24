
variable "region" {
  type        = string
  description = "The AWS and HCP region to create resources in"
}

variable "ssh_key_name" {
  type        = string
  description = "key name to use for SSH access"
}

variable "ssh_private_key" {
  type        = string
  description = "The private key to use for SSH access"
}

variable "tower_password" {
  type        = string
  description = "The private key to use for SSH access"
}