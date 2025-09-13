variable "region" { default = "us-east-1" }
variable "vpc_cidr" { default = "10.0.0.0/16" }

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "ami" {
  description = "AMI ID for Ubuntu"
  type        = string
}

variable "instance_type" {
  default = "t3.medium"
}

variable "key_name" {
  description = "SSH keypair name"
  type        = string
}
