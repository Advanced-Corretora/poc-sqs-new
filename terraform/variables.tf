// #### VARIÁVEIS OBRIGATÓRIAS ####
variable "region" {
  type = string
}
// #### VARIÁVEIS ECR E ECS ####
variable "service_name" {
  type = string
}
variable "env" {
  type = string
}
variable "department" {
  type = string
}
// #### VARÍÁVEIS SOMENTE ECS ####
variable "ecr_image_tag" {
  type = string
  default = ""
}
variable "domain_name" {
  type = string
  default = ""
}
variable "subdomain_prefix" {
  type = string
  default = ""
}

variable "health_check_path" {
  type = string
  default = "api/v1/"
}

variable "vpc_id" {
  type = string
  default = ""
}

variable "public_subnets_id" {
  type = string
  default = ""
}

variable "container_memory" {
  type = number
  default = 512
}

variable "container_cpu" {
  type = number
  default = 256
}

variable "container_quantity" {
  type = number
  default = 1
}