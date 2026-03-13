FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV APT_INSTALL="apt-get install \
      -y \
      -o dpkg::options::=--force-confdef \
      -o dpkg::options::=--force-confold"

RUN \
  apt-get update && \
  yes '' | $APT_INSTALL \
    autoconf \
    automake \
    curl \
    git \
    make \
    unzip \
    upx \
    xz-utils \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*
