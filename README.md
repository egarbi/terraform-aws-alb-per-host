AWS ALB per Host Terraform module
========================

Terraform module which create an internet-facing ALB supporting host-based routing.
This can be used to expose that need public access. For instance, an ngnix proxy, or your own web app.
The same ALB can be shared with several different public services.
If you plan to use it for more than 1 service make sure your SSL certificate match all your domain name services, This is seen as `Certificate Subject Alt Name` field.  

Usage
-----

```hcl
module "webALB" {
  source                = "git::https://github.com/egarbi/terraform-aws-alb-per-host"
  name                = "web-postPaid"
  subnet_ids          = [ "subnet-AZa", "subnet-AZb", "subnet-AZc" ]
  environment         = "testing"
  security_groups     = [ "sg-3546635" ]
  vpc_id              = "vpc-183763"
  log_bucket          = "alb-logs"
  zone_id             = "ZDOXX02XXUITZ"
  ssl_arn             = "arn:aws:acm:eu-west-1:12345678901:certificate/abcd54-06sbdh5-js64-hsg36sjsm34"
  ssl_policy          = "ELBSecurityPolicy-2015-05"
  hosts               = "example"
  services            = "example-testing-tg"
}
```
