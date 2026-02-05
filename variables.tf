########################
##       GLOBAL       ##
########################

variable "common_tags" {
  type = object({
    ManagedBy = string
    Owner     = string
    Project   = string
  })

  default = {
    ManagedBy = "Terraform"
    Owner     = "Thomas Tuminaro"
    Project   = "tf-aws-infra-project"
  }
}

########################
##         VPC        ##
########################

variable "vpc" {
  type = object({
    vpc_cidr_block = string
    vpc_name       = string
  })

  default = {
    vpc_cidr_block = "10.0.0.0/16"
    vpc_name       = "tf-aws-infra-project-vpc"
  }

  validation {
    condition     = can(cidrnetmask(var.vpc.vpc_cidr_block))
    error_message = "${var.vpc.vpc_cidr_block} is not a valid subnet mask for the VPC."
  }

  validation {
    condition     = startswith(var.vpc.vpc_name, "tf-aws-infra-project")
    error_message = "Please name the VPC starting with the project name tf-aws-infra-project-#####."
  }
}

variable "subnets" {
  type = map(object({
    subnet_cidr_block = string
    enable_public     = bool
  }))

  validation {
    condition     = alltrue([for sub in var.subnets : can(cidrnetmask(sub.subnet_cidr_block))])
    error_message = "Please select valid subnet CIDR blocks."
  }

  validation {
    condition     = alltrue([for key in keys(var.subnets) : startswith(key, "tf-aws-infra-project-subnet-")])
    error_message = "Please prefix your subnet names with tf-aws-infra-project-subnet-#####."
  }

  validation {
    condition     = length([for k, v in var.subnets : k if v.enable_public == true]) == 1
    error_message = "You must configure one public subnet, no more, no less."
  }

  validation {
    condition     = length([for k, v in var.subnets : k if v.enable_public == false]) == 2
    error_message = "You must configure two private subnets, no more, no less."
  }
}

variable "security_groups" {
  type = map(object({
    sg_description = string
    sg_cidr_ipv4   = list(string)
    sg_ports       = list(number)
  }))

  validation {
    condition     = alltrue([for key in keys(var.security_groups) : startswith(key, "tf-aws-infra-project-sg-")])
    error_message = "Please prefix your security group name by tf-aws-infra-project-#####."
  }

  validation {
    condition = alltrue([for sg in var.security_groups : alltrue([
    for cidr in sg.sg_cidr_ipv4 : can(cidrnetmask(cidr))])])
    error_message = "Please enter valid CIDR blocks for your security group egress rules, in variable security_groups."
  }

  validation {
    condition = alltrue([for sg in var.security_groups : alltrue([
    for port in sg.sg_ports : port > 0 && port < 10000 && port == floor(port)])])
    error_message = "Please use valid ports (in range 1 -> 10000) for your security groups ingress rules, in variable security_groups."
  }
}

########################
##         S3         ##
########################

variable "s3" {
  type = string

  validation {
    condition     = startswith(var.s3, "tf-aws-infra-project-")
    error_message = "Please prefix your bucket with tf-aws-infra-project-#####"
  }
}

########################
##        EC2         ##
########################

variable "ec2_instance" {
  type = map(object({
    ec2_type   = string
    ec2_subnet = string
  }))
}