# Grabbing AMI for Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Creating a launch template, will be needed for ASG 

resource "aws_launch_template" "server" {
  name     = "${var.common_tags.Project}-ec2-template"
  image_id = data.aws_ami.ubuntu.id
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }
  instance_type = "t3.micro"

  user_data = base64encode(templatefile("${path.module}/initial_setup.sh", {
    bucket_name = var.s3
  }))

  update_default_version = true
}

resource "aws_instance" "servers" {
  for_each = var.ec2_instance

  launch_template {
    name = aws_launch_template.server.name
  }

  subnet_id = aws_subnet.private_ec2[each.value.ec2_subnet].id
  vpc_security_group_ids = [ aws_security_group.groups[local.ec2_sg].id ]

  root_block_device {
    delete_on_termination = true
    volume_size           = 20
    volume_type           = "gp3"
  }

  tags = merge(var.common_tags, {
    Name = "${each.key}"
  })

  depends_on = [ aws_launch_template.server,
    aws_vpc_security_group_egress_rule.egress,
    aws_vpc_security_group_ingress_rule.ingress,
    aws_s3_object.app,
    aws_route_table_association.nat ]
}

