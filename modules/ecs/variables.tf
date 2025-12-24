variable "region" {
  description = "The AWS region to deploy to"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy resources into"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "frontend_container_image" {
  description = "ECR image for frontend service"
  type        = string
}

variable "backend_container_image" {
  description = "ECR image for backend service"
  type        = string
}

variable "db_private_ip" {
  description = "Private IP of database EC2 instance"
  type        = string
}

variable "frontend_cert_arn" {
  description = "ACM certificate ARN for madeep.shop"
  type        = string
}

variable "backend_cert_arn" {
  description = "ACM certificate ARN for backend.madeep.shop"
  type        = string
}


