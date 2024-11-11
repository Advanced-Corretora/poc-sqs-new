terraform {
  required_version = ">=1.8.5"
  required_providers {
    aws = ">=5.68.0"
  }
  backend "s3" {
  }
}

provider "aws" {
  region = var.region
}

module "ecr" {
  source = "./modules/ecr"
  service_name = var.service_name
  env = var.env
  department = var.department
}

module "ecs" {
  source = "./modules/ecs"
  service_name = var.service_name
  env = var.env
  department = var.department
  ecr_repository_url = module.ecr.ecr_repository_url
  container_memory = var.container_memory
  container_cpu = var.container_cpu
  container_quantity = var.container_quantity
  vpc_id= var.vpc_id 
  public_subnets_id = split(",", var.public_subnets_id)
  domain_name = var.domain_name
  subdomain_name = "${var.subdomain_prefix}.${var.domain_name}"
  ecr_image_tag = var.ecr_image_tag
  health_check_path = var.health_check_path
}
