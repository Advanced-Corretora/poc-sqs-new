locals {
  full_name = "${var.env}-${var.service_name}"
}

resource "aws_ecs_cluster" "cluster" {
  name = "${local.full_name}-cluster"
  tags = {
    Department = var.department
    Environment = var.env
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${local.full_name}-execution-role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "${local.full_name}-td"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "${local.full_name}-td",
      "image": "${var.ecr_repository_url}:${var.ecr_image_tag}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": ${var.container_memory},
      "cpu": ${var.container_cpu}
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # use Fargate as the launch type
  network_mode             = "awsvpc"    # add the AWS VPN network mode as this is required for Fargate
  memory                   = var.container_memory         # Specify the memory the container requires
  cpu                      = var.container_cpu         # Specify the CPU the container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
  tags = {
    Department = var.department
    Environment = var.env
  }
}


resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "load_balancer_security_group" {
  vpc_id = var.vpc_id
  name = "${local.full_name}-lb-sg"
  tags = {
    Department = var.department
    Environment = var.env
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_lb_http" {
  security_group_id = aws_security_group.load_balancer_security_group.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol = "tcp"
  tags = {
    Name = "${local.full_name}-ingress-lb-http-rule"
    Department = var.department
    Environment = var.env
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_lb_https" {
  security_group_id = aws_security_group.load_balancer_security_group.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
   tags = {
    Name = "${local.full_name}-ingress-lb-https-rule"
    Department = var.department
    Environment = var.env
  }
}

resource "aws_vpc_security_group_egress_rule" "egress_lb" {
  security_group_id = aws_security_group.load_balancer_security_group.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = -1
  to_port = -1
  ip_protocol = -1
   tags = {
    Name = "${local.full_name}-egress-lb-rule"
    Department = var.department
    Environment = var.env
  }
}

resource "aws_alb" "application_load_balancer" {
  name               = "${local.full_name}-lb" #load balancer name
  load_balancer_type = "application"
  subnets = var.public_subnets_id
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  tags = {
    Department = var.department
    Environment = var.env
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "${local.full_name}-tg"
  vpc_id      = var.vpc_id
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  health_check {
    path = "/${var.health_check_path}"
    healthy_threshold = 5
    unhealthy_threshold = 2 
  }
  tags = {
    Department = var.department
    Environment = var.env
  }
}

###############################################################################

data "aws_route53_zone" "app" {
  name = var.domain_name
}

resource "aws_route53_record" "dev" {
  zone_id = data.aws_route53_zone.app.zone_id
  type    = "CNAME"
  name    = var.subdomain_name
  records = [aws_alb.application_load_balancer.dns_name]
  ttl     = "30"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.subdomain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.full_name}-cert"
    Department = var.department
    Environment = var.env
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  zone_id = data.aws_route53_zone.app.id
  name = each.value.name
  type = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}


resource "aws_lb_listener" "listener_http" {
  load_balancer_arn = "${aws_alb.application_load_balancer.arn}" #  load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # target group
  }
  tags = {
    Name = "${local.full_name}-listener-http"
    Department = var.department
    Environment = var.env
  }
}

resource "aws_lb_listener" "listener_https" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
  tags = {
    Name = "${local.full_name}-listener-https"
    Department = var.department
    Environment = var.env
  }
}

###############################################################################

resource "aws_security_group" "service_security_group" {
  vpc_id = var.vpc_id
  name = "${local.full_name}-sg"
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Department = var.department
    Environment = var.env
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${local.full_name}"     # Name the service
  cluster         = "${aws_ecs_cluster.cluster.id}"   # Reference the created Cluster
  task_definition = "${aws_ecs_task_definition.task_definition.arn}" # Reference the task that the service will spin up
  launch_type     = "FARGATE"
  desired_count   = var.container_quantity
  health_check_grace_period_seconds = 10
  wait_for_steady_state = true

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Reference the target group
    container_name   = "${aws_ecs_task_definition.task_definition.family}"
    container_port   = 3000 # Specify the container port
  }

  network_configuration {
    subnets          = var.public_subnets_id
    assign_public_ip = true     # Provide the containers with public IPs
    security_groups = ["${aws_security_group.service_security_group.id}"]
  }
  tags = {
    Department = var.department
    Environment = var.env
  }
}