output "bucket" {
  value = aws_s3_bucket.benchmark.id
}

#output "folders" {
#  value = aws_s3_object.create_folders
#}

output "iam_policy_profile" {
  value = aws_iam_policy.policy.arn
}

output "launch_template" {
  value = aws_launch_template.benchmark_launch_template.id
}

output "security_group" {
  value = aws_security_group.ssh_access.id
}

output "rendered_policy" {
  value = data.aws_iam_policy_document.policy.json
}

