## Logging

There is a pre-built policy and role specific to permissions for an Execution Role to allow Lambda to write logs to CloudWatch Logs.

## Things To Consider

- adding in Interface Endpoint to the Lambda managed services VPC where the Lambda runs to connect privately to a private VPC
    + AWS still manages HA
    + concurrency isn't limited b/c not sharing ENIs with other services in VPC (i.e., if the Lambda was moved into a private VPC)
- reserve concurrency for the particular lambda function
- if execution latency is an issue, perhaps consider provisioned concurrency (of course, there are additional costs)
- monitor using CloudWatch and X-Ray

## References

- [Create a Lambda function using a container image](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)
- [Building Lambda functions with Rust](https://docs.aws.amazon.com/lambda/latest/dg/lambda-rust.html)
- [Rust Runtime for AWS Lambda](https://github.com/awslabs/aws-lambda-rust-runtime)

