# tf-aws-infra-project

First project managing AWS infrastructure 

IAM ***** 
=> EC2 IAM roles and policies
=> IAM instance profile : create role so that EC2 instance can access S3

EC2 *****
=> 2 instances for light web server - can use minimal Flask that can interact with DB 
=> instances behing an ASG and ALB 
=> ALB connected to public network
=> instances connected to private network to communicate with databases 
=> security groups 
=> as a test import user data to the VM 
=> AMI : will base on basic ubuntu and configure manually using the user data 

VPC *****
=> one VPC
=> 3 subnets, one public two privates
=> one gateway
=> security groups 
=> route tables + associations 

S3 *****
=> a simple bucket used to store images of website 

RDS *****
=> 2 db instances storing some information for the website 
=> db subnet group
=> security group 