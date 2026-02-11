/*
aws_lb : main resource 
aws_lb_target_group & aws_lb_target_group_attachment
aws_lb_listener & aws_lb_listener_rule

LB requires at least 2 subnets to be created to balance traffic - and subnets should be placed in different AZs 

*/

resource "aws_lb" "front_end" {
  name               = "${var.common_tags.Project}-lb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.groups["tf-aws-infra-project-sg-ec2"].id]
  subnets         = [for sub in aws_subnet.public : sub.id if sub.map_public_ip_on_launch]

  tags = merge(var.common_tags, {
    Name = "tf-aws-infra-project-lb"
  })
}

resource "aws_lb_target_group" "web" {
  name     = "${var.common_tags.Project}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "web" {
  for_each         = aws_instance.servers
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.servers[each.key].id
  port             = 80
}