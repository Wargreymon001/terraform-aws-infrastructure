#DEFINIMOS LAS VARIABLES QUE VAMOS A USAR EN NUESTRO PROYECTO DE TERRAFORM, EL CODIGO SE VUELVE REUTILIZABLE.

variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "instance_name"{
    description = "Server Name"
    type = string
    }