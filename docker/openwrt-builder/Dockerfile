FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

RUN apt-get update && apt-get install -y --no-install-recommends \
    asciidoc \
    autoconf \
    automake \
    autopoint \
    bash \
    binutils \
    bison \
    build-essential \
    bzip2 \
    ca-certificates \
    ccache \
    clang \
    cmake \
    curl \
    device-tree-compiler \
    file \
    flex \
    g++-multilib \
    gawk \
    gcc-multilib \
    gettext \
    git \
    gperf \
    jq \
    libelf-dev \
    libglib2.0-dev \
    libncurses-dev \
    libssl-dev \
    libtool \
    msmtp \
    ninja-build \
    patch \
    pkgconf \
    python3 \
    python3-pyelftools \
    python3-setuptools \
    qemu-utils \
    rsync \
    subversion \
    swig \
    texinfo \
    time \
    uglifyjs \
    unzip \
    wget \
    xmlto \
    xxd \
    xz-utils \
    zlib1g-dev \
    zstd \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

USER ubuntu
WORKDIR /home/ubuntu
