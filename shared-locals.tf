locals {
  ########################
  ##         VPC        ##
  ######################## 
  public_subnet_name = join(",", [for key, value in var.subnets : key if value.enable_public == true])

  public_subnets  = { for k, v in var.subnets : k => v if v.enable_public }
  private_subnets = { for k, v in var.subnets : k => v if !v.enable_public }

  ec2_subnets = { for k, v in var.subnets : k => v if strcontains(k, "ec2") }
  db_subnets  = { for k, v in var.subnets : k => v if strcontains(k, "db") }

  default_public_subnet = join(",", [for key, value in var.subnets : key if value.enable_public && value.is_default])

  ec2_sg = join(",", [for key, value in var.security_groups : key if strcontains(key, "ec2")])
  db_sg  = join(",", [for key, value in var.security_groups : key if strcontains(key, "db")])

  sg_ingress_rules = flatten([
    for sg_name, sg_config in var.security_groups : [
      for ingress_rule in sg_config.sg_ingress_rules : {
        sg_name   = sg_name
        port_from = ingress_rule.ingress_port_from
        cidr      = ingress_rule.ingress_cidr
        port_to   = ingress_rule.ingress_port_to
      }
    ]
  ])

  sg_egress_rules = flatten([
    for sg_name, sg_config in var.security_groups : [
      for egress_rule in sg_config.sg_egress_rules : {
        sg_name   = sg_name
        port_from = egress_rule.egress_port_from
        cidr      = egress_rule.egress_cidr
        port_to   = egress_rule.egress_port_to
      }
    ]
  ])

  ########################
  ##         EC2        ##
  ######################## 

  azs = [for sub in aws_subnet.public : sub.availability_zone]

  ########################
  ##                    ##
  ########################

}