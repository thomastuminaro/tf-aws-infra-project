# VPC specific local block 
locals {
  public_subnet_name = join(",", [for key, value in var.subnets : key if value.enable_public == true])
 /*  sg_rules = flatten([
    for sg_name, sg_config in var.security_groups : [
      for port in sg_config.sg_ports : [
        for cidr in sg_config.sg_cidr_ipv4 : {
          sg_name = sg_name
          port    = port
          cidr    = cidr
        }
      ]
    ]
  ]) */

  sg_ingress_rules = flatten([
    for sg_name, sg_config in var.security_groups : [
      for ingress_rule in sg_config.sg_ingress_rules : {
          sg_name = sg_name
          port_from    = ingress_rule.ingress_port_from
          cidr    = ingress_rule.ingress_cidr
          port_to = ingress_rule.ingress_port_to
        } 
    ]
  ])

  sg_egress_rules = flatten([
    for sg_name, sg_config in var.security_groups : [
      for egress_rule in sg_config.sg_egress_rules : {
          sg_name = sg_name
          port_from    = egress_rule.egress_port_from
          cidr    = egress_rule.egress_cidr
          port_to = egress_rule.egress_port_to
        } 
    ]
  ])
}

# Creating the main VPC resource for the application 
resource "aws_vpc" "main" {
  cidr_block = var.vpc.vpc_cidr_block

  tags = merge(var.common_tags, {
    Name = var.vpc.vpc_name
  })
}

# Creating subnets resource for the application 
resource "aws_subnet" "this" {
  for_each                = var.subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.subnet_cidr_block
  map_public_ip_on_launch = each.value.enable_public

  tags = merge(var.common_tags, {
    Name = "${each.key}"
  })
}

# Creating gateway for communications
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "tf-aws-infra-project-gw"
  })
}

# Creating route to internet 
resource "aws_route_table" "default" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(var.common_tags, {
    Name = "tf-aws-infra-project-route-table"
  })
}

# Associate public subnet to the internet route
resource "aws_route_table_association" "internet" {
  subnet_id      = aws_subnet.this[local.public_subnet_name].id
  route_table_id = aws_route_table.default.id
}

# Creating security group to allow web traffic to web interfaces
resource "aws_security_group" "groups" {
  for_each = var.security_groups
  name     = each.key
  vpc_id   = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${each.key}"
  })
}

# Grabbing prefix list of AWS console for EC2 connect
data "aws_ec2_managed_prefix_list" "console" {
  name = "com.amazonaws.eu-west-3.ec2-instance-connect"
}

# Adding a custom security group ingress rule to enable traffic from the web console
resource "aws_vpc_security_group_ingress_rule" "console" {
  for_each = aws_security_group.groups
  security_group_id = aws_security_group.groups[each.key].id
  ip_protocol = -1
  prefix_list_id = data.aws_ec2_managed_prefix_list.console.id

}

# Creating ingress rules for all security groups 
resource "aws_vpc_security_group_ingress_rule" "ingress" {
  count             = length(local.sg_ingress_rules)
  security_group_id = aws_security_group.groups[local.sg_ingress_rules[count.index].sg_name].id
  ip_protocol       = "tcp"
  from_port         = local.sg_ingress_rules[count.index].port_from
  to_port           = local.sg_ingress_rules[count.index].port_to
  cidr_ipv4         = local.sg_ingress_rules[count.index].cidr

  tags = merge(var.common_tags, {
    Name = "Ingress-port-${local.sg_ingress_rules[count.index].port_from}:${local.sg_ingress_rules[count.index].port_to}-${local.sg_ingress_rules[count.index].cidr}"
  })

  depends_on = [aws_security_group.groups]
}

# Creating egress rules for all security groups 
resource "aws_vpc_security_group_egress_rule" "egress" {
  count             = length(local.sg_egress_rules)
  security_group_id = aws_security_group.groups[local.sg_egress_rules[count.index].sg_name].id
  ip_protocol       = "tcp"
  from_port         = local.sg_egress_rules[count.index].port_from
  to_port           = local.sg_egress_rules[count.index].port_to
  cidr_ipv4         = local.sg_egress_rules[count.index].cidr

  tags = merge(var.common_tags, {
    Name = "Egress-port-${local.sg_egress_rules[count.index].port_from}:${local.sg_egress_rules[count.index].port_to}-${local.sg_egress_rules[count.index].cidr}"
  })

  depends_on = [aws_security_group.groups]
}