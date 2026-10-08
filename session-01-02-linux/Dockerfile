FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends \
    adduser procps iproute2 iputils-ping dnsutils traceroute curl wget \
    netcat-openbsd net-tools systemd ca-certificates git \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /work
CMD ["bash"]
