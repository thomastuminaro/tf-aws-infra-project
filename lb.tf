resource "aws_lb" "front_end" {
  name               = "${var.common_tags.Project}-lb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.groups[local.ec2_sg].id]
  subnets         = [for sub in aws_subnet.public : sub.id if sub.map_public_ip_on_launch]

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-lb"
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

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}