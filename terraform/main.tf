provider "aws" {
  region = "us-east-1"
}

# https://awspolicygen.s3.amazonaws.com/policygen.html
# https://policysim.aws.amazon.com/home/index.jsp

#resource "aws_iam_user" "admin_user" {
#  name          = "kilgore-trout"
#  force_destroy = true
#  tags = {
#    Description = "Main Administrator Account"
#  }
#}
#
#data "aws_iam_policy" "AdministratorAccess" {
#  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
#}
#
#resource "aws_iam_user_policy_attachment" "admin_access" {
#  user       = aws_iam_user.admin_user.name
#  policy_arn = data.aws_iam_policy.AdministratorAccess.arn
#}

resource "aws_security_group" "ssh_access" {
  name        = "${var.bucket_name}-sg"
  description = "SSH access"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "benchmark" {
  bucket        = var.bucket_name
  force_destroy = true
}

#resource "aws_s3_bucket_policy" "put" {
#  bucket = var.bucket_name
#  policy = data.aws_iam_policy_document.policy.json
#}

resource "aws_s3_object" "create_folders" {
  bucket   = aws_s3_bucket.benchmark.bucket
  key      = each.value
  for_each = var.bucket_folders
}

resource "aws_launch_template" "benchmark_launch_template" {
  name = "benchmarks-lt"
  iam_instance_profile {
    name = aws_iam_instance_profile.profile.role
  }
  image_id      = "ami-0ebfd941bbafe70c6"
  instance_type = "t2.micro"
  key_name      = "benchmark"
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }
  vpc_security_group_ids = [aws_security_group.ssh_access.id]
  user_data              = filebase64("benchmark.sh")
}

#resource "aws_key_pair" "ec2_access" {
#}

