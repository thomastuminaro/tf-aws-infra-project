# Configuring IAM role, policy to allow EC2 instances to communicate with S3 bucket
# As exercise will manually create policy even if s3 RO exists already

/* resources :
=> aws_iam_role
=> aws_iam_instance_profile 
=> aws_iam_policy
=> aws_iam_role_policy_attachment  */

# Creating the policy which allows S3 bucket access
resource "aws_iam_policy" "ros3" {
  name        = "tf-aws-infra-project-readonly-s3"
  path        = "/"
  description = "Policy to allow read-only access to S3 bucket from EC2 instances."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [                 # https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazons3.html#amazons3-actions-as-permissions 
          "s3:GetObject",          # Retrieve objects from bucket
          "s3:GetObjectVersion",   # Retrieve specific version of object 
          "s3:ListBucket",         # List objects in the bucket 
          "s3:ListBucketVersions", # List versions of all objects in the bucket
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.bucket.arn}" # check more dynamic way
      },
    ]
  })

  depends_on = [ aws_instance.servers, aws_s3_bucket.bucket ]
}

# Creating the role 
resource "aws_iam_role" "ec2" {
  name = "tf-aws-infra-project-ec2-role"

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Attaching policy to the role 
resource "aws_iam_role_policy_attachment" "ec2" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ros3.arn
}

# Creating the instance profile
resource "aws_iam_instance_profile" "ec2" {
  name = "tf-aws-infra-project-ec2-profile"
  role = aws_iam_role.ec2.name
}
