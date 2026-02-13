# Creating the main VPC resource for the application 
resource "aws_vpc" "main" {
  cidr_block = var.vpc.vpc_cidr_block

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-${var.vpc.vpc_name}"
  })
}

# Grabbing available AZs for availability
data "aws_availability_zones" "available" {
  state = "available"
}

# Creating public subnets resource for the LB 
resource "aws_subnet" "public" {
  for_each                = local.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.subnet_cidr_block
  map_public_ip_on_launch = each.value.enable_public
  availability_zone = data.aws_availability_zones.available.names[index([for k in keys(local.public_subnets) : k], each.key)
  % length(data.aws_availability_zones.available.names)]

  tags = merge(var.common_tags, {
    Name   = "${each.key}"
    Public = "TRUE"
  })
}

# Creating private subnets resource for the EC2 instances 
resource "aws_subnet" "private_ec2" {
  for_each                = local.ec2_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.subnet_cidr_block
  map_public_ip_on_launch = each.value.enable_public
  availability_zone       = local.azs[index([for k in keys(local.ec2_subnets) : k], each.key) % length(local.azs)]

  tags = merge(var.common_tags, {
    Name   = "${each.key}"
    Public = "FALSE"
  })
}

# Creating private subnets resource for the DB instances 
resource "aws_subnet" "private_db" {
  for_each                = local.db_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.subnet_cidr_block
  map_public_ip_on_launch = each.value.enable_public
  availability_zone       = local.azs[index([for k in keys(local.db_subnets) : k], each.key) % length(local.azs)]

  tags = merge(var.common_tags, {
    Name   = "${each.key}"
    Public = "FALSE"
  })
}

# Creating gateway for communications
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-gw"
  })
}

# Creating Elastic IP for the NAT gateway
resource "aws_eip" "ip" {
  domain           = "vpc"
  public_ipv4_pool = "amazon"
}

# Creating NAT gateway for internal components to reach internet 
resource "aws_nat_gateway" "gw" {
  availability_mode = "zonal"
  allocation_id     = aws_eip.ip.id
  connectivity_type = "public"

  subnet_id = aws_subnet.public[local.default_public_subnet].id

  depends_on = [aws_internet_gateway.gw]
}

# Creating route to internet 
resource "aws_route_table" "default" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-route-table"
  })
}

# Associate public subnet to the internet route
resource "aws_route_table_association" "internet" {
  for_each       = local.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.default.id
}

# Creating route table for EC2 instances to NAT GW
resource "aws_route_table" "nat" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-route-NAT-table"
  })
}

resource "aws_route_table_association" "nat" {
  for_each       = local.ec2_subnets
  subnet_id      = aws_subnet.private_ec2[each.key].id
  route_table_id = aws_route_table.nat.id
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

/* # Grabbing prefix list of AWS console for EC2 connect
data "aws_ec2_managed_prefix_list" "console" {
  name = "com.amazonaws.eu-west-3.ec2-instance-connect"
}

# Adding a custom security group ingress rule to enable traffic from the web console
resource "aws_vpc_security_group_ingress_rule" "console" {
  for_each          = aws_security_group.groups
  security_group_id = aws_security_group.groups[each.key].id
  ip_protocol       = -1
  prefix_list_id    = data.aws_ec2_managed_prefix_list.console.id
} */

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