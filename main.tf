provider "aws" {
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket         = "terraform-bucket-heliosolutions"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    use_lockfile = true
  }
}
module "vpc" {
  source   = "./modules/vpc"
  region   = "ap-south-1"  # Specify your region here
  vpc_cidr = "10.0.0.0/16" # Specify your VPC CIDR here
}

module "ecs" {
  source          = "./modules/ecs"
  region          = "ap-south-1"  # Specify your region here
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets

  # Specify the container images for each service
  frontend_container_image = "785186659004.dkr.ecr.ap-south-1.amazonaws.com/frontend:new"
  backend_container_image  = "785186659004.dkr.ecr.ap-south-1.amazonaws.com/backend:new"

  db_private_ip = module.ec2.database_private_ip
  frontend_cert_arn = "arn:aws:acm:ap-south-1:785186659004:certificate/dc98aa3e-9af6-40dc-9726-7a598f24521d"
  backend_cert_arn  = "arn:aws:acm:ap-south-1:785186659004:certificate/ff8815ca-d925-4990-afca-b34014debba1"
}

module "ec2" {
  source = "./modules/ec2"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids  = module.vpc.public_subnets

  key_name      = "heliosolutions"
  ubuntu_ami_id = "ami-02b8269d5e85954ef"
  ecs_backend_sg_id = module.ecs.backend_sg_id
}
