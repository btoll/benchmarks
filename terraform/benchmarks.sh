#!/bin/bash -x
#shellcheck disable=1091

mkdir /root/.aws

cat <<EOF > /root/.aws/credentials
[profile benchmarks]
role_arn = arn:aws:iam::296062564641:role/benchmarks1337-role
credential_source = Ec2InstanceMetadata
region = us-east-1
EOF

#yum install gcc gcc-c++ kernel-devel make git unzip -y
yum install git unzip -y

curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
unzip awscliv2.zip
./aws/install

#curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly
#export HOME=/root
#. "$HOME/.cargo/env"
#git clone https://github.com/0xPolygonZero/plonky2
LOGFILE=$(date +%s).plonky2.log
#cd plonky2 && RUSTFLAGS="-C target-cpu=native" cargo bench --package plonky2 | tee "$LOGFILE"
echo hello world | tee "$LOGFILE"

aws s3 cp "$LOGFILE" s3://benchmarks1337/benchmarks/

