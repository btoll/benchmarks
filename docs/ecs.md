## Add Instance To ECS Cluster

In the `user-data` section:

```bash
#!/bin/bash
echo ECS_CLUSTER=benchmarks >> /etc/ecs/ecs.config
```

## Profile

```
$ aws configure --profile ilovedevopsnot-kilgore-trout
```

## Create

If creating the `default` cluster, there is no need to specify a cluster-name.

```bash
$ aws ecs create-cluster
```

## Create ECR Repository

Login for a private repo:

```bash
$ aws configure
aws ecr get-login-password | docker login -u AWS --password-stdin 296062564641.dkr.ecr.us-east-1.amazonaws.com/kilgore-trout/benchmarks
```

Login for a public repo:

```bash
$ aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/g8y0f4e6
```

Then, create the repository.

> I guess the user `AWS` is a magic user, I never created it.

## Tag And Push

```bash
$ docker tag benchmarks:latest public.ecr.aws/g8y0f4e6/benchmarks:latest
$ docker push public.ecr.aws/g8y0f4e6/benchmarks:latest
```

## List

```bash
$ aws ecs list-container-instances
```

## List Images In A Repository In A Public Registry

```bash
$ aws ecr-public describe-images --repository-name benchmarks
{
    "imageDetails": [
        {
            "registryId": "296062564641",
            "repositoryName": "benchmarks",
            "imageDigest": "sha256:d37ada95d47ad12224c205a938129df7a3e52345828b4fa27b03a98825d1e2e7",
            "imageTags": [
                "latest"
            ],
            "imageSizeInBytes": 3040,
            "imagePushedAt": "2024-09-23T20:11:24.294000-04:00",
            "imageManifestMediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "artifactMediaType": "application/vnd.docker.container.image.v1+json"
        }
    ]
}
```

## References

- [Creating an Amazon ECS task for the EC2 launch type with the AWS CLI](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_AWSCLI_EC2.html)
- [AWS Fargate](https://aws.amazon.com/fargate/)

