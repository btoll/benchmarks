data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role" {
  name               = "${var.bucket_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

#    resources = ["*"]

data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "*"
#      aws_s3_bucket.benchmark.arn,
#      "${aws_s3_bucket.benchmark.arn}/*",
    ]
#    principals {
#      type        = "AWS"
#      identifiers = ["s3.amazonaws.com"]
#    }
  }
}

resource "aws_iam_policy" "policy" {
  name        = "${var.bucket_name}-policy"
  description = "Policy for EC2 instances that run benchmarks and upload to S3"
  policy      = data.aws_iam_policy_document.policy.json
}

#resource "aws_iam_role_policy_attachment" "attachment" {
#  role       = aws_iam_role.role.name
#  policy_arn = aws_iam_policy.policy.arn
#}

resource "aws_iam_role_policy" "s3-put-policy" {
  name   = "${var.bucket_name}-s3-put-policy"
  role   = aws_iam_role.role.name
  policy = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.bucket_name}-profile"
  role = aws_iam_role.role.name
}

