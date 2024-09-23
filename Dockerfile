FROM debian:bookworm-slim

RUN groupadd --gid 1000 noroot \
    && useradd \
    --create-home \
    --home-dir /home/noroot \
    --uid 1000 \
    --gid 1000 \
    --shell /bin/bash \
    --no-log-init noroot

RUN apt-get update && \
    apt-get install -y \
        curl \
        less \
        openssh-client \
        unzip

RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install

COPY benchmarks.sh ./

#USER noroot
#WORKDIR /home/noroot

ENTRYPOINT ["/benchmarks.sh"]
CMD ["--help"]

