## List Amazon AMIs

```bash
$ aws ec2 describe-images --owners amazon
```

## List Instances

```bash
$ aws ec2 describe-instances
```

## Get Instance Metadata

```bash
$ aws ec2 describe-instances --instance-id i-0c73f1fbd2b40a194 --query Reservations[].Instances[].MetadataOptions
[
    {
        "State": "applied",
        "HttpTokens": "required",
        "HttpPutResponseHopLimit": 2,
        "HttpEndpoint": "enabled",
        "HttpProtocolIpv6": "disabled",
        "InstanceMetadataTags": "disabled"
    }
]

```

## Create (Run) Instance

```bash
$ aws ec2 run-instances --launch-template LaunchTemplateName=benchmarks --instance-type t2.medium
```

> This will override the default instance type in the launch template.

Create and get instance ID:

```bash
$ aws ec2 run-instances --launch-template LaunchTemplateName=benchmarks --query Instances[0].InstanceId --output text
```

## Get Public DNS

```bash
$ aws ec2 describe-instances --instance-ids i-09b8f1b152470ff40 --query Reservations[0].Instances[0].PublicDnsName --output text
```

> `--output text` removes the quotes.

## Delete Instance

```bash
$ aws ec2 terminate-instances --instance-ids i-0048968ef97b2d738
{
    "TerminatingInstances": [
        {
            "CurrentState": {
                "Code": 32,
                "Name": "shutting-down"
            },
            "InstanceId": "i-0048968ef97b2d738",
            "PreviousState": {
                "Code": 16,
                "Name": "running"
            }
        }
    ]
}
```

## Describe Launch Template

```bash
$ aws ec2 describe-launch-templates --launch-template-names benchmarks
{
    "LaunchTemplates": [
        {
            "LaunchTemplateId": "lt-01b488994af020321",
            "LaunchTemplateName": "benchmarks",
            "CreateTime": "2024-09-24T18:08:33+00:00",
            "CreatedBy": "arn:aws:iam::296062564641:user/kilgore-trout",
            "DefaultVersionNumber": 1,
            "LatestVersionNumber": 1
        }
    ]
}
```

As table data:

```bash
$ aws ec2 describe-launch-templates --launch-template-names benchmarks --output table
----------------------------------------------------------------------------
|                          DescribeLaunchTemplates                         |
+--------------------------------------------------------------------------+
||                             LaunchTemplates                            ||
|+-----------------------+------------------------------------------------+|
||  CreateTime           |  2024-09-24T18:08:33+00:00                     ||
||  CreatedBy            |  arn:aws:iam::296062564641:user/kilgore-trout  ||
||  DefaultVersionNumber |  1                                             ||
||  LatestVersionNumber  |  1                                             ||
||  LaunchTemplateId     |  lt-01b488994af020321                          ||
||  LaunchTemplateName   |  benchmarks                                   ||
|+-----------------------+------------------------------------------------+|
```

```bash
$ aws ec2 get-launch-template-data --instance-id i-001d5fc5f04d34b9a --query LaunchTemplateData
{
    "EbsOptimized": false,
    "BlockDeviceMappings": [],
    "NetworkInterfaces": [],
    "ImageId": "ami-0ebfd941bbafe70c6",
    "InstanceType": "m1.small",
    "KeyName": "test",
    "Monitoring": {
        "Enabled": false
    },
    "Placement": {
        "AvailabilityZone": "us-east-1c",
        "GroupName": "",
        "Tenancy": "default"
    },
    "DisableApiTermination": false,
    "InstanceInitiatedShutdownBehavior": "stop",
    "UserData":
	...
```

> This data can be used to create a launch template.

## Get `user-data` From Launch Template Data

```bash
$ aws ec2 get-launch-template-data --instance-id i-001d5fc5f04d34b9a --query LaunchTemplateData.UserData --output text | base64 -d
#!/bin/bash -x
yum install gcc gcc-c++ kernel-devel make git -y
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly
export HOME=/root
. "$HOME/.cargo/env"
git clone https://github.com/0xPolygonZero/plonky2
cd plonky2 && RUSTFLAGS="-C target-cpu=native" cargo bench --package plonky2
```

> `--output text` removes the quotes.

## Get Instance Types That Satisfy Resource Criteria

```bash
$ aws ec2 get-instance-types-from-instance-requirements --cli-input-json file://attributes.json --output table
```

`attributes.json`

```json

{
    "ArchitectureTypes": [
        "x86_64"
    ],
    "VirtualizationTypes": [
        "hvm"
    ],
    "InstanceRequirements": {
        "VCpuCount": {
            "Min": 0,
            "Max": 4
        },
        "MemoryMiB": {
            "Min": 0,
            "Max": 4096
        }
    }
}

```

## Notes

- choosing an hvm ami affects the permissions of `/var/log/cloud-init-output.log` in that it is no longer readable by `other` (or `all`) - this breaks tailing the logs in the client

## References

- [I created an IAM role, but the role doesn't appear in the dropdown list when I launch an instance. What do I do?](https://repost.aws/knowledge-center/iam-role-not-in-list)
- [Use Amazon EC2 instance metadata for AWS CLI credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-metadata.html)
- [Access instance metadata for an EC2 instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html)

