data "aws_availability_zones" "available" {}

locals {
  # azs = length(data.aws_availability_zones.available.names)
  azs = 2
}

resource "aws_vpc" "main" {
  cidr_block = "172.17.0.0/16"

  tags = {
    Name = "spp-cognito-poc"
  }
}

resource "aws_subnet" "private" {
  count             = local.azs
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id

  tags = {
    Name = "spp-cognito-poc-private-${count.index}"
  }
}

resource "aws_subnet" "public" {
  count                   = local.azs
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 20 + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true

  tags = {
    Name = "spp-cognito-poc-public-${count.index}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "spp-cognito-poc"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_eip" "gw" {
  count      = local.azs
  vpc        = true
  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "spp-cognito-poc-${count.index}"
  }
}

resource "aws_nat_gateway" "gw" {
  count         = local.azs
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gw.*.id, count.index)

  tags = {
    Name = "spp-cognito-poc-${count.index}"
  }
}

resource "aws_route_table" "private" {
  count  = local.azs
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gw.*.id, count.index)
  }

  tags = {
    Name = "spp-cognito-poc-private-${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count          = local.azs
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_security_group" "lb" {
  name        = "spp-cognito-poc-alb"
  description = "controls access to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "spp-cognito-poc-ecs"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_route53_zone" "crosscutting" {
  name = "crosscutting.aws.onsdigital.uk."
}

resource "aws_route53_record" "poc_client" {
  zone_id = data.aws_route53_zone.crosscutting.zone_id
  name    = "spp-cognito-poc.crosscutting.aws.onsdigital.uk"
  type    = "CNAME"
  ttl     = 60

  records = [aws_alb.main.dns_name]
}

resource "aws_route53_record" "fake_baw" {
  zone_id = data.aws_route53_zone.crosscutting.zone_id
  name    = "spp-cognito-poc-baw.crosscutting.aws.onsdigital.uk"
  type    = "CNAME"
  ttl     = 60

  records = [aws_alb.fake_baw.dns_name]
}

resource "aws_acm_certificate" "poc_client" {
  domain_name       = "spp-cognito-poc.crosscutting.aws.onsdigital.uk"
  validation_method = "DNS"

  subject_alternative_names = ["spp-cognito-poc-baw.crosscutting.aws.onsdigital.uk"]
}

resource "aws_route53_record" "poc_client_validation" {
  for_each = {
    for dvo in aws_acm_certificate.poc_client.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.crosscutting.zone_id
}

resource "aws_acm_certificate_validation" "poc_client" {
  certificate_arn         = aws_acm_certificate.poc_client.arn
  validation_record_fqdns = [for record in aws_route53_record.poc_client_validation : record.fqdn]
}

resource "aws_alb" "main" {
  name            = "spp-cognito-poc"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}

resource "aws_alb_target_group" "app_http" {
  name        = "spp-cognito-poc-http"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    matcher = "200-399"
  }
}

resource "aws_alb_listener" "front_end_https" {
  load_balancer_arn = aws_alb.main.id
  port              = "443"
  protocol          = "HTTPS"

  certificate_arn = aws_acm_certificate_validation.poc_client.certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.app_http.id
    type             = "forward"
  }
}

resource "aws_alb" "fake_baw" {
  name            = "spp-cognito-poc-fake-baw"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}

resource "aws_alb_target_group" "app_http_fake_baw" {
  name        = "spp-cognito-poc-http-fake-baw"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    matcher = "200-399"
  }
}

resource "aws_alb_listener" "front_end_https_fake_baw" {
  load_balancer_arn = aws_alb.fake_baw.id
  port              = "443"
  protocol          = "HTTPS"

  certificate_arn = aws_acm_certificate_validation.poc_client.certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.app_http_fake_baw.id
    type             = "forward"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "spp-cognito-poc"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "spp-cognito-poc-client"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = <<DEFINITION
[
  {
    "cpu": 256,
    "image": "sambryant/spp-poc-client",
    "memory": 512,
    "name": "spp-cognito-poc-client",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 5000,
        "hostPort": 5000
      }
    ],
    "environment": [
      {
        "name": "CLIENT_ID",
        "value": "${aws_cognito_user_pool_client.poc_client.id}"
      },
      {
        "name": "CLIENT_SECRET",
        "value": "${aws_cognito_user_pool_client.poc_client.client_secret}"
      },
      {
        "name": "COGNITO_DOMAIN",
        "value": "https://${aws_cognito_user_pool_domain.cognito_poc.domain}.auth.${var.region}.amazoncognito.com"
      },
      {
        "name": "COGNITO_PUBLIC_KEY_URL",
        "value": "https://${aws_cognito_user_pool.cognito_poc.endpoint}/.well-known/jwks.json"
      },
      {
        "name": "APP_HOST",
        "value": "https://spp-cognito-poc.crosscutting.aws.onsdigital.uk"
      },
      {
        "name": "SESSION_COOKIE_SECURE",
        "value": "True"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "main" {
  name            = "spp-cognito-poc-client"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets         = aws_subnet.private.*.id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app_http.id
    container_name   = "spp-cognito-poc-client"
    container_port   = "5000"
  }

  depends_on = [
    aws_alb_listener.front_end_https,
  ]
}

resource "aws_ecs_task_definition" "fake_baw" {
  family                   = "spp-cognito-poc-fake-baw"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = <<DEFINITION
[
  {
    "cpu": 256,
    "image": "sambryant/spp-fake-baw",
    "memory": 512,
    "name": "spp-cognito-poc-fake-baw",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 5000,
        "hostPort": 5000
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "fake_baw" {
  name            = "spp-cognito-poc-fake-baw"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fake_baw.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets         = aws_subnet.private.*.id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app_http_fake_baw.id
    container_name   = "spp-cognito-poc-fake-baw"
    container_port   = "5000"
  }

  depends_on = [
    aws_alb_listener.front_end_https_fake_baw,
  ]
}
