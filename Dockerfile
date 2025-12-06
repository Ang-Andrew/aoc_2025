FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    git \
    python3 \
    python3-pip \
    libreadline-dev \
    tcl-dev \
    libffi-dev \
    graphviz \
    xdot \
    && rm -rf /var/lib/apt/lists/*

# Download and install OSS CAD Suite
RUN curl -L https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2025-12-03/oss-cad-suite-linux-x64-20251203.tgz | tar xz -C /opt

# Set PATH
ENV PATH="/opt/oss-cad-suite/bin:${PATH}"

# Install Cocotb
RUN pip3 install cocotb cocotb-test pytest

WORKDIR /project
