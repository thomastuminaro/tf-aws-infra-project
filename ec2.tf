# aws_network_interface_attachment

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
  name     = "tf-aws-infra-project-ec2-template"
  image_id = data.aws_ami.ubuntu.id
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }
  instance_type = "t3.micro"

  /* network_interfaces {
    device_index = 0
    subnet_id       = aws_subnet.private["tf-aws-infra-project-subnet-private-ec2"].id
    security_groups = [aws_security_group.groups["tf-aws-infra-project-sg-ec2"].id]
  } */

  network_interfaces {
    device_index = 0
    associate_public_ip_address = true
    subnet_id       = aws_subnet.public["tf-aws-infra-project-subnet-public-1"].id
    security_groups = [aws_security_group.groups["tf-aws-infra-project-sg-ec2"].id]
  }

  user_data = base64encode(templatefile("${path.module}/initial_setup.sh", {
    bucket_name = var.s3
  }))

  #user_data = filebase64("${path.module}/initial_setup.sh")

  update_default_version = true
}

resource "aws_instance" "servers" {
  for_each = var.ec2_instance

  launch_template {
    name = aws_launch_template.server.name
  }

  availability_zone = "eu-west-3a"

 /*  network_interface {
    network_interface_id = 1
    subnet_id       = aws_subnet.private["tf-aws-infra-project-subnet-private-ec2"].id
    security_groups = [aws_security_group.groups["tf-aws-infra-project-sg-ec2"].id]
  } */

  root_block_device {
    delete_on_termination = true
    volume_size           = 20
    volume_type           = "gp3"
  }

  tags = merge(var.common_tags, {
      Name = "${each.key}"
  })

  depends_on = [aws_launch_template.server,
    aws_vpc_security_group_ingress_rule.console,
    aws_vpc_security_group_egress_rule.egress,
    aws_vpc_security_group_ingress_rule.ingress,
  aws_s3_object.app]
}

