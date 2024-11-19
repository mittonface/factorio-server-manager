FROM --platform=linux/amd64 factoriotools/factorio:stable


COPY ./docker-entrypoint.sh /docker-entrypoint.sh
COPY ./server/map-settings.json /factorio/config/map-settings.json
COPY ./server/map-gen-settings.json /factorio/config/map-gen-settings.json
COPY ./server/server-settings.json /factorio/config/server-settings.json


# Combine package installation and cleanup in one layer
RUN apt-get update && \
    apt-get install -y \
    nfs-common \
    jq \
    awscli \
    git \
    binutils \
    rustc \
    cargo \
    pkg-config \
    libssl-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clone and build EFS utils with memory optimization

RUN git clone https://github.com/aws/efs-utils && \
    cd efs-utils && \
    CARGO_NET_GIT_FETCH_WITH_CLI=true ./build-deb.sh && \
    apt-get update && \
    apt-get install -y ./build/amazon-efs-utils*deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /efs-utils

# Install Python packages
RUN python3 -m pip install --no-cache-dir botocore amazon-efs-utils


ENTRYPOINT [ "/docker-entrypoint.sh" ]