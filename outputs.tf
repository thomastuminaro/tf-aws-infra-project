output "test" {
  value = index([for k in keys(local.public_subnets) : k], "tf-aws-infra-project-subnet-public-1")
}
