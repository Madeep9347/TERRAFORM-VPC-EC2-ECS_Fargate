variable "vpc_id" {
  description = "VPC ID"
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}


variable "key_name" {
  description = "EC2 key pair name"
}

variable "ubuntu_ami_id" {
  description = "Ubuntu AMI ID"
}
##ecs sg
variable "ecs_backend_sg_id" {
  description = "Security group ID of ECS backend service"
  type        = string
}
