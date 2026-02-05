subnets = {
  "tf-aws-infra-project-subnet-public" = {
    subnet_cidr_block = "10.0.10.0/24"
    enable_public     = true
  },
  "tf-aws-infra-project-subnet-private-ec2" = {
    subnet_cidr_block = "10.0.20.0/24"
    enable_public     = false
  },
  "tf-aws-infra-project-subnet-private-db" = {
    subnet_cidr_block = "10.0.30.0/24"
    enable_public     = false
  }
}

security_groups = {
  "tf-aws-infra-project-sg-ec2" = {
    sg_description = "Security group for EC2 instances, allows only traffic to DBs and Web - will need to check for LB."
    sg_cidr_ipv4   = ["10.0.20.0/24", "10.0.30.0/24"]
    sg_ports       = ["80", "22"]
  },
  "tf-aws-infra-project-sg-db" = {
    sg_description = "Security group for DB instances, allows only traffic EC2 and to other DBs."
    sg_cidr_ipv4   = ["10.0.20.0/24", "10.0.30.0/24"]
    sg_ports       = ["3306"]
  }
}

s3 = "tf-aws-infra-project-bucket"

ec2_instance = {
  "tf-aws-infra-project-server1" = {
    ec2_type   = "t3.micro"
    ec2_subnet = "tf-aws-infra-project-subnet-public"
  }/* ,
  "tf-aws-infra-project-server2" = {
    ec2_type   = "t3.micro"
    ec2_subnet = "tf-aws-infra-project-subnet-private-ec2"
  } */
}