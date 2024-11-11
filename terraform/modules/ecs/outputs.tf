output "alb_dns_name_url" {
  value = aws_alb.application_load_balancer.dns_name
}

output "service_url" {
  value = "https://${var.subdomain_name}"
}