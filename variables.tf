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
    vpc_name       = "vpc"
  }

  validation {
    condition     = can(cidrnetmask(var.vpc.vpc_cidr_block))
    error_message = "${var.vpc.vpc_cidr_block} is not a valid subnet mask for the VPC."
  }

  /* validation {
    condition     = startswith(var.vpc.vpc_name, "tf-aws-infra-project")
    error_message = "Please name the VPC starting with the project name tf-aws-infra-project-#####."
  } */
}

variable "subnets" {
  type = map(object({
    subnet_cidr_block = string
    enable_public     = bool
    is_default = optional(bool, false)
  }))

  validation {
    condition     = alltrue([for sub in var.subnets : can(cidrnetmask(sub.subnet_cidr_block))])
    error_message = "Please select valid subnet CIDR blocks."
  }

  validation {
    condition     = alltrue([for name in keys(var.subnets) : startswith(name, "tf-aws-infra-project-subnet-")])
    error_message = "Please prefix your subnet names with tf-aws-infra-project-subnet-#####."
  }

  /* validation {
    condition     = length([for k, v in var.subnets : k if v.enable_public == false]) == 3
    error_message = "You must configure two private subnets, no more, no less."
  } */

  validation {
    condition = length([ for sub in var.subnets : sub if sub.is_default && sub.enable_public ]) == 1
    error_message = "Please use is_default flag for one public subnet."
  }

  validation {
    condition     = length([for sub in var.subnets : sub if sub.enable_public]) == 2 || length([for sub in var.subnets : sub if sub.enable_public]) == 3
    error_message = "You need to configure exactly two or three public subnets, use the enable_public option."
  }

  validation {
    condition     = length([for name, sub in var.subnets : name if strcontains(name, "ec2")]) >= 2 
    error_message = "You need to configure at least two subnets for EC2 instances and include ec2 in the subnet names."
  }
}

variable "security_groups" {
  type = map(object({
    sg_description = string

    sg_ingress_rules = map(object({
      ingress_cidr      = string
      ingress_port_from = number
      ingress_port_to   = number
    }))

    sg_egress_rules = map(object({
      egress_cidr      = string
      egress_port_from = number
      egress_port_to   = number
    }))
  }))

  validation {
    condition     = alltrue([for name in keys(var.security_groups) : startswith(name, "tf-aws-infra-project-sg-")])
    error_message = "Please prefix your security group name by tf-aws-infra-project-#####."
  }

  validation {
    condition = alltrue([for group in var.security_groups : alltrue([
      for rule in group.sg_ingress_rules :
    can(cidrnetmask(rule.ingress_cidr))])])
    error_message = "One of your security group ingress rule does not contain a valid CIDR."
  }

  validation {
    condition = alltrue([for group in var.security_groups : alltrue([
      for rule in group.sg_egress_rules :
    can(cidrnetmask(rule.egress_cidr))])])
    error_message = "One of your security group egress rule does not contain a valid CIDR."
  }

  validation {
    condition = alltrue([for group in var.security_groups : alltrue([
      for rule in group.sg_ingress_rules :
      rule.ingress_port_from == floor(rule.ingress_port_from)
      && rule.ingress_port_from >= 0 && rule.ingress_port_from <= 65535 && rule.ingress_port_to <= 65535 && rule.ingress_port_to >= 0
    && rule.ingress_port_from <= rule.ingress_port_to])])
    error_message = "Please provide correct values for your ingress rule ports, between 0 and 65535, use same value if one port only. \nRange port_from:port_to."
  }

  validation {
    condition = alltrue([for group in var.security_groups : alltrue([
      for rule in group.sg_egress_rules :
      rule.egress_port_from == floor(rule.egress_port_from)
      && rule.egress_port_from >= 0 && rule.egress_port_from <= 65535 && rule.egress_port_to <= 65535 && rule.egress_port_to >= 0
    && rule.egress_port_from <= rule.egress_port_to])])
    error_message = "Please provide correct values for your egress rule ports, between 0 and 65535, use same value if one port only. \nRange port_from:port_to"
  }

  validation {
    condition = length([ for name in keys(var.security_groups) : name if strcontains(name, "ec2") ]) == 1
    error_message = "The module only supports one security group for EC2 instances."
  }
}

########################
##         S3         ##
########################

variable "s3" {
  type = string

  validation {
    condition     = startswith(var.s3, var.common_tags.Project)
    error_message = "Please prefix your bucket with your project name."
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