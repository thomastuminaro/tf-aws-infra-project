subnets = {
  "tf-aws-infra-project-subnet-public-1" = {
    subnet_cidr_block = "10.0.10.0/24"
    enable_public     = true
    is_default = true
  },
  "tf-aws-infra-project-subnet-public-2" = {
    subnet_cidr_block = "10.0.11.0/24"
    enable_public     = true
  },
  "tf-aws-infra-project-subnet-private-ec2-1" = {
    subnet_cidr_block = "10.0.20.0/24"
    enable_public     = false
  },
  "tf-aws-infra-project-subnet-private-ec2-2" = {
    subnet_cidr_block = "10.0.21.0/24"
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
    sg_ingress_rules = {
      "traffic-from-vpc-all" = {
        ingress_cidr      = "10.0.0.0/16"
        ingress_port_from = 0
        ingress_port_to   = 65535
      },
      "traffic-from-http-all" = {
        ingress_cidr      = "0.0.0.0/0"
        ingress_port_from = 80
        ingress_port_to   = 80
      }
    }
    sg_egress_rules = {
      "traffic-to-vpc-all" = {
        egress_cidr      = "10.0.0.0/16"
        egress_port_from = 0
        egress_port_to   = 65535
      },
      "traffic-to-https-all" = {
        egress_cidr      = "0.0.0.0/0"
        egress_port_from = 443
        egress_port_to   = 443
      },
      "traffic-to-http-all" = {
        egress_cidr      = "0.0.0.0/0"
        egress_port_from = 80
        egress_port_to   = 80
      }
    }
  },
  "tf-aws-infra-project-sg-db" = {
    sg_description = "Security group for DB instances, allows only traffic EC2 and to other DBs."
    sg_ingress_rules = {
      "traffic-from-vpc-all" = {
        ingress_cidr      = "10.0.0.0/16"
        ingress_port_from = 3306
        ingress_port_to   = 3306
      }
    }
    sg_egress_rules = {
      "traffic-to-vpc-all" = {
        egress_cidr      = "10.0.0.0/16"
        egress_port_from = 0
        egress_port_to   = 65535
      }
    }
  }
}

s3 = "tf-aws-infra-project-bucket"

ec2_instance = {
  "tf-aws-infra-project-server1" = {
    ec2_type   = "t3.micro"
    ec2_subnet = "tf-aws-infra-project-subnet-private-ec2-1"
  },
  "tf-aws-infra-project-server2" = {
    ec2_type   = "t3.micro"
    ec2_subnet = "tf-aws-infra-project-subnet-private-ec2-2"
  }
}