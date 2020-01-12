FROM ubuntu:16.04

# Install the build dependencies
RUN apt-get update && apt-get install -y \
        python \
        python-pip \
        wget \
        unzip \
        git \
        build-essential \
        pass \
        gnupg2 \
        jq

RUN pip install awscli --upgrade --user && \
    mv /root/.local/bin/* /usr/local/bin

RUN apt-get install -y docker.io

WORKDIR /tmp
COPY . /tmp/

RUN ls -l

RUN chmod +x start.sh

CMD ["./start.sh", "${event}", "${build_version}", "${aws_account}", "${aws_access_key_id}", "${aws_secret_access_key}"]