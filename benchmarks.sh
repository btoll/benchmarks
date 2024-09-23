#!/bin/bash
#shellcheck disable=2064

set -exo pipefail

LANG=C
umask 0022

trap cleanup EXIT

CPU=
MEMORY=
ATTR_FILE=
INSTANCE_TYPE=
TAIL=1

cleanup() {
    rm -f "$ATTR_FILE"
}

usage() {
    printf "Usage: %s --instance-type \"f1.2xlarge\" [ --cpu 8 --memory 4096 ]\n\n" "$0"
    printf "Args:\n"
    printf -- "-c, --cpu            : The number of cores.\n"
    printf -- "-i, --instance-type  : The name of the instance type. Defaults to \`t2.micro\`.\n"
    printf -- "-m, --memory         : The amount of memory. This is determined by the chosen instance type.\n"
    printf -- "-f, --tail           : Tail the logs on the instance.  Must have access to the private key.\n"
    printf -- "-h, --help           : Show usage.\n"
    exit "$1"
}

while [ "$#" -gt 0 ]
do
    OPT="$1"
    case $OPT in
        -c|--cpu) shift; CPU=$1 ;;
        -h|--help) usage 0 ;;
        -i|--instance-type) shift; INSTANCE_TYPE=$1 ;;
        -m|--memory) shift; MEMORY=$1 ;;
        -f|--tail) TAIL=0 ;;
        *) printf "Unknown flag %s\n" "$1"; usage 1 ;;
    esac
    shift
done

list_instance_types() {
    ATTR_FILE=$(mktemp)
cat << EOF > "$ATTR_FILE"
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
            "Max": $CPU
        },
        "MemoryMiB": {
            "Min": 0,
            "Max": $MEMORY
        }
    }
}
EOF

    aws ec2 get-instance-types-from-instance-requirements \
        --cli-input-json "file://$ATTR_FILE" \
        --output table
}

if [ -z "$CPU" ] && [ -z "$MEMORY" ] && [ -z "$INSTANCE_TYPE" ]
then
    printf "[ERROR] Must provide arguments.\n"
    usage 1
elif [ -n "$CPU" ] && [ -n "$MEMORY" ] && [ -z "$INSTANCE_TYPE" ]
then
    list_instance_types
elif [ -z "$MEMORY" ] && [ -n "$INSTANCE_TYPE" ]
then
    printf "[INFO] Creating ec2 instance..."
    if [ -n "$CPU" ]
    then
        if ! INSTANCE_ID=$(aws ec2 run-instances \
                        --launch-template LaunchTemplateName=benchmarks-lt \
                        --instance-type "$INSTANCE_TYPE" \
                        --cpu-options "CoreCount=$CPU,ThreadsPerCore=1" \
                        --query Instances[0].InstanceId \
                        --output text)
        then
            printf "[ERROR] The instance could not be created.\n"
            exit 1
        fi
    else
        if ! INSTANCE_ID=$(aws ec2 run-instances \
                        --launch-template LaunchTemplateName=benchmarks-lt \
                        --instance-type "$INSTANCE_TYPE" \
                        --query Instances[0].InstanceId \
                        --output text)
        then
            printf "[ERROR] The instance could not be created.\n"
            exit 1
        fi
    fi

    printf "Done!\n"

    if ! IP=$(aws ec2 describe-instances \
                    --instance-ids "$INSTANCE_ID" \
                    --query Reservations[0].Instances[0].PublicDnsName \
                    --output text)
    then
        printf "[ERROR] The public DNS name could not be retrieved from the instance.\n"
        exit 1
    fi

    printf "[INFO]     Instance ID = %s\n" "$INSTANCE_ID"
    printf "[INFO] Public DNS name = %s\n" "$IP"

    if [ "$TAIL" -eq 0 ]
    then
        printf "[INFO] Waiting for the server to come online.  Logging will begin shortly.\n"
        while ! ssh \
                    -o StrictHostKeyChecking=no \
                    -i "$HOME/benchmarks.pem" \
                    ec2-user@"$IP" tail -f /var/log/cloud-init-output.log 2> /dev/null
        do
            sleep 2
        done
    fi
else
    printf "[ERROR] Please try again!"
fi

