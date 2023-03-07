# Dockerfile for the dev container image
# From Ubuntu 22.04
# include g++, git, cmake, flex, bison, and gdb

FROM ubuntu:22.04

LABEL maintainer="yangyf83 yangyf83@aliyun.com"

# install packages

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    cmake \
    flex \
    bison \
    gdb \
    && rm -rf /var/lib/apt/lists/*

# set the default shell to bash instead of sh
# ENV SHELL /bin/bash

# set the default working directory
# WORKDIR /workspaces

# set the default user
USER vscode

# set the default command
# CMD ["/bin/bash"]

# set the default git user name and email
# RUN git config --global user.name "yangyf83" && git config --global user.email "yangyf83@aliyun.com"
