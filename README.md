# benchmarks

This project creates a simple shell script that will create an ec2 instance in the default VPC and run the `plonky2` benchmarking suite.  A default [launch template](benchmarks_launch_template.json) has been created, and the tool uses this to save the user from having to input a lot of information that will be the same from run to run.

As per the requirements, the user is allowed to input the following three paramaters:

- `instance type`
- `cpu`
- `memory` (in `MiB`)

> If an instance type isn't specified, the tool will default to `t2.micro`, which is probably not what you want.

## Considerations

- Keep it simple.
- Use the least amount of tools as possible.
- Since presumably developers will be benchmarking as well as other technical groups, let's not use tools that the average developer isn't using on a day-to-day basis.
    + In other words, let's not use tools that require a learning curve themselves.
- Use AWS, but don't require devs to have an intimate knowledge of the cloud platform.
    + Expectations on requiring an IAM user and an (shared) access key are reasonable per user, but don't mandate anyone to log into the AWS Console.

## Usage

```bash
$ ./benchmarks.sh -h
Usage: ./benchmarks.sh --instance-type "f1.2xlarge" [ --cpu 8 --memory 4096 ]

Args:
-c, --cpu            : The number of cores.
-i, --instance-type  : The name of the instance type. Defaults to `t2.micro`.
-m, --memory         : The amount of memory. This is determined by the chosen instance type.
-f, --tail           : Tail the logs on the instance.  Must have access to the private key.
-h, --help           : Show usage.
```

Here are some use cases:

- The instance type is known:

    ```bash
    ./benchmarks.sh --instance-type t2.2xlarge
    ```

- The instance type is known and the number of cores are specified:

    ```bash
    ./benchmarks.sh --instance-type t2.2xlarge --cpu 8
    ```

- The instance type is not known and the user wants to choose based on memory and CPU requirements:

    ```bash
    ./benchmarks.sh --memory 61035 --cpu 8
    ```

    + This produces a paginated list (using `less`) of instance types to choose that fit the memory and CPU requirements.
    + Once an instance type is selected, the tool can be re-run with it as a parameter.

- Running the tool and tailing the logs:

    ```bash
    ./benchmarks.sh --instance-type t2.2xlarge --tail
    ```


The tool can be run from a `bash` shell in a terminal or in a container using Podman or Docker.  If choosing the to run it as a container, I highly suggest using Podman.

Running the tool in a container has a number of appealing options:

- Easy.  No need to clone the project.  Also, it depends on the `bash` shell, which not everyone uses.  Installing a shell is easy, but so is running a container, as many devs will already have a container engine installed on their system.
- Refer to the first bullet point.

If running from a shell, the user's AWS credentials must be in `$HOME/.aws/credentials` or exported as environment variables.  In addition, if wanting to tail the logs, then the SSH access key is expected to be in the home directory with the name of `benchmarks.pem` (`chmod 0400`).

Tailing the logs from the shell:

```bash
$ ./benchmarks.sh --instance-type t2.large -f
```

Tailing the logs from in a container:

```bash
$ podman run \
    --rm \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
    -v ~/benchmarks.pem:/root/benchmarks.pem \
    benchmarks --instance-type t2.2xlarge -f
```

> When bind mounting the secret key, it must be bound to `/root` in the container.

Note that the logs will be everything that the `user-data` script (see below) is outputting.  This is a nice way to locally capture the output, in addition to it be uploading to S3.  The `tee` utility is especially useful here.

## Other Services Considered

See the `docs/` directory for miscellaneous notes and commands I compiled while researching several of these options.

- AWS Lambda
    + This is a great option, especially given that it can run a container.
    + Although it is serverless, initially it seemed to tick some of the boxes.
    + However:
        - It has a maximum execution time of 15 minutes.
        - It doesn't allow the user to specify CPU, instead opting to adjust that in proportion to the amount of memory that is configured.
- AWS ECS in EC2
    + This is an attractive option because it allows the containers to be managed by the ECS service and for the use of auto-scaling groups.
    + However:
        - I'm didn't see a way to create an instance on-the-fly and join it to the ECS cluster that was compatible with the definition that was initially given to the container instances on the creation of the ECS cluster (I could have missed that, though).
- AWS EBS
    + Another appealing choice, as this could be attached to each instance as it was created.  However, although it does allow for multi-attachment to many EC2 instances at a time, that was extra configuration and it still didn't help to address another requirement of the assignment: putting the logs in a publicly-accessible place.  Although technically accessible, it puts an addition burden on the user to either mount the volume to an instance to get the logs or to create a snapshot and import into S3 (so why not just upload to S3 in the first place).
- AWS Fargate
    + This option wasn't really considered as it essentially is advertised as a fully serverless option.

## Areas Of Improvement

In no particular order:

- the naming convention of benchmark files uploaded to S3 could be better, such as including information about
    + the instance type
    + the number of cores
    + date of test (currently it's a Unix timestamp, admittedly not the most user friendly)
        - for the initial tests, I wanted something that would (probably) not have any collisions with existing filenames

- allow the user to pass in a launch template
    + immediately makes the tool much more configurable

- don't hardcode the location and name of the access key in the script

## `user-data`

Here are the commands that will be run every time an EC2 instance is created by the CLI tool:

```bash
#!/bin/bash -x

mkdir /root/.aws

cat <<EOF > /root/.aws/credentials
[profile benchmarks]
role_arn = arn:aws:iam::296062564641:role/benchmarks-s3
credential_source = Ec2InstanceMetadata
region = us-east-1
EOF

yum install gcc gcc-c++ kernel-devel make git unzip -y

curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
unzip awscliv2.zip
./aws/install

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly
export HOME=/root
. "$HOME/.cargo/env"
git clone https://github.com/0xPolygonZero/plonky2
LOGFILE=$(date +%s).plonky2.log
cd plonky2 && RUSTFLAGS="-C target-cpu=native" cargo bench --package plonky2 | tee "$LOGFILE"

aws s3 cp "$LOGFILE" s3://benchmarks1337/plonky2/
```

Here's a fun way to get the `user-data`:

```bash
$ aws ec2 get-launch-template-data --instance-id i-001d5fc5f04d34b9a --query LaunchTemplateData.UserData --output text | base64 -d
```

## More Tailing The Logs

It's always possible to tail the logs separately from the tool.  Simply copy the public DNS name outputted when the `benchmarks` script is raun and plug it into the command below:

```bash
$ ssh -o StrictHostKeyChecking=no -i ~/benchmarks.pem ec2-user@ec2-44-195-0-160.compute-1.amazonaws.com tail -f /var/log/cloud-init-output.log
```

## Podman

Podman can build from a `Dockerfile`:

```bash
$ podman build -t benchmarks .
```

```bash
$ podman run \
    --rm \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
    benchmarks
Usage: /benchmarks.sh --instance-type "f1.2xlarge" [ --cpu 8 --memory 4096 ]

Args:
-c, --cpu            : The number of cores.
-i, --instance-type  : The name of the instance type. Defaults to `t2.micro`.
-m, --memory         : The amount of memory. This is determined by the chosen instance type.
-f, --tail           : Tail the logs on the instance.  Must have access to the private key.
-h, --help           : Show usage.
```

List the instance types that fall into the range specified by `--cpu` and `--memory`:

```bash
$ podman run \
    --rm \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
    benchmarks --cpu 8 --memory 4096
```

```bash
$ podman run --rm -it -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION -v ~/benchmarks.pem:/root/benchmarks.pem benchmarks --instance-type t2.micro -f
[INFO] Creating ec2 instance...Done!
[INFO]     Instance ID = i-0f693151a910d63c2
[INFO] Public DNS name = ec2-35-175-146-82.compute-1.amazonaws.com
[INFO] Waiting for the server to come online.  Logging will begin shortly.
```

> Set an alias to help rid yourself of Docker:
> ```bash
> alias docker="podman"
> ```

## How It Works

- EC2 launch template
- Security group
- Custom role and profile for any EC2 instance to upload to S3
- Enable metadata to be accessible in the instance

I would love to discuss this in more detail with members of the team!  I've also included the files I used when creating a VM using Vagrant.

## References

- [Plonky2](https://github.com/0xPolygonZero/plonky2)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [AWS Pricing Calculator](https://calculator.aws)

