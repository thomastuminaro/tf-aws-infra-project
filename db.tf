/*
DB aws resources : 
=> add security group
=> aws_db_instance -> sg configured there 
=> create vars for size, username and password etc
=> aws_db_subnet_group to add DB to its subnet 

Script : 
=> add mysql to the EC2 so it can connect to DB
=> create php script to connect to DB 
https://www.w3schools.com/php/php_mysql_create.asp
*/

resource "aws_db_instance" "db" {
  for_each               = var.db_instance
  allocated_storage      = each.value.db_storage
  engine                 = each.value.db_engine
  engine_version         = "8.0"
  db_name                = each.key
  username               = each.value.db_user
  password               = each.value.db_password
  instance_class         = each.value.db_class
  vpc_security_group_ids = [ aws_security_group.groups[local.db_sg].id ]
  db_subnet_group_name   = aws_db_subnet_group.db[each.key].name
  skip_final_snapshot = true 

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-${each.key}"
  })

  depends_on = [ aws_db_subnet_group.db ]
}

resource "aws_db_subnet_group" "db" {
  for_each   = var.db_instance
  name       = "${each.key}-subnet-group"
  subnet_ids = [for sub in aws_subnet.private_db : sub.id]

  tags = merge(var.common_tags, {
    Name = "${var.common_tags.Project}-${each.key}-subnet-group"
  })
}