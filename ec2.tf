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
  name = "tf-aws-infra-project-ec2-template"
  image_id = data.aws_ami.ubuntu.id
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }
  instance_type = "t3.micro"

  network_interfaces {
    subnet_id = aws_subnet.this["tf-aws-infra-project-subnet-public"].id
    security_groups = [aws_security_group.groups["tf-aws-infra-project-sg-ec2"].id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
        Name = "tf-aws-infra-project-server1"
    })
  }

  user_data = filebase64("${path.module}/initial_setup.sh")
}

resource "aws_instance" "servers" {
  launch_template {
    name = aws_launch_template.server.name
  }

  root_block_device {
    delete_on_termination = true
    volume_size = 20
    volume_type = "gp3"
  }

  depends_on = [ aws_launch_template.server ]
}