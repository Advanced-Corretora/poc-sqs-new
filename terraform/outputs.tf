output "ecr_repository_url" {
  value = module.ecr.ecr_repository_url
}

output "service_url" {
  value = module.ecs.service_url
}

output "alb_dns_name_url" {
  value = module.ecs.alb_dns_name_url
}