variable "service_name" {
  type = string
}

variable "env" {
  type = string
}

variable "department" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "ecr_image_tag" {
}

variable "container_memory" {
  type = number
}

variable "container_cpu" {
  type = number
}

variable "container_quantity" {
  type = number
}

variable "vpc_id" {
  type = string
}

variable "public_subnets_id" {
  type = list(any)
}

variable "domain_name" {
  type = string
}

variable "subdomain_name" {
  type = string
}

variable "health_check_path" {
  type = string
}