/**
 * The ALB module creates an ALB, target_groups, listener rules,
 * and the route53 records needed.
 */

variable "name" {}

variable "subnet_ids" {
  type = "list"
  description = "List of subnets where LB live, tipically one per AZ"
}

variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "security_groups" {
  type = "list"
  description = "List of security group to associate with the LB"
}

variable "backend_proto" {
  default = "HTTP"
}

variable "healthcheck" {
  default = {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    path                = "/"
    interval            = 30
  }
}

variable "hosts" {
  type       = "list"
  description = "List of ALB's Content-Based Routing host to match"
  default    = []
}

variable "services" {
  type       = "list"
  description = "List of services where traffic of the matching hosts will be forwarded"
  default    = []
}

variable "ports" {
  type       = "list"
  description = "List of backend_ports associated with each service"
  default    = []
}

variable "zone_id" {
  description = "Route53 zone ID to use for dns_name"
}

variable "log_bucket" {
  description = "S3 bucket name to write ALB logs into"
}

variable "vpc_id" {}

variable "ssl_arn" {}

variable "ssl_policy" {}

/**
 * Resources.
 */

resource "aws_alb" "main" {
  name            = "${var.name}-${var.environment}"
  internal        = "false"
  subnets         = [ "${var.subnet_ids}" ]
  security_groups = [ "${var.security_groups}" ]


  access_logs {
    bucket = "${var.log_bucket}"
  }

  tags {
    Name     = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_alb_target_group" "main" {
  count        = "${length(var.services)}"
  name         = "${var.services[count.index]}-${var.environment}"
  port         = "${var.ports[count.index]}"
  protocol     = "${var.backend_proto}"
  vpc_id       = "${var.vpc_id}"
  health_check = [ "${var.healthcheck}" ]
}

resource "aws_alb_listener" "main" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "${var.ssl_arn}"
  ssl_policy        = "${var.ssl_policy}"

  default_action {
    target_group_arn = "${aws_alb_target_group.main.0.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "main" {
  count        = "${length(var.hosts)}"
  listener_arn = "${aws_alb_listener.main.arn}"
  priority     = "${count.index + 100 }"

  action {
    type             = "forward"
    target_group_arn = "${element(aws_alb_target_group.main.*.arn, count.index)}"
  }

  condition {
    field  = "host-header"
    values = ["${var.hosts[count.index]}.*"]
  }
  lifecycle {
    ignore_changes = ["priority"]
  }
}

# Add ALB record on DNS
resource "aws_route53_record" "main" {
  count = "${length(var.hosts)}"
  zone_id = "${var.zone_id}"
  name    = "${var.hosts[count.index]}"
  type    = "A"

  alias {
    name                   = "${aws_alb.main.dns_name}"
    zone_id                = "${aws_alb.main.zone_id}"
    evaluate_target_health = false
  }
}

/**
 * Outputs.
 */

// The ALB name.
output "name" {
  value = "${aws_alb.main.name}"
}

// The ALB ID.
output "id" {
  value = "${aws_alb.main.id}"
}

// The ALB ARN
output "arn" {
  value = "${aws_alb.main.arn}"
}

// The ALB listener ARN
output "listener_arn" {
  value = "${aws_alb_listener.main.arn}"
}

// The ALB dns_name.
output "dns" {
  value = "${aws_alb.main.dns_name}"
}

// FQDN built using the zone domain and name
output "fqdn" {
  value = "${aws_route53_record.main.fqdn}"
}

// The zone id of the ALB
output "zone_id" {
  value = "${aws_alb.main.zone_id}"
}

// The target-group id of the ALB
output "target_groups" {
  value = [ "${aws_alb_target_group.main.*.id}" ]
}
