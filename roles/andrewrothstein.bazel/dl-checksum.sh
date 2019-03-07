#!/usr/bin/env sh
VER=0.21.0
MIRROR=https://github.com/bazelbuild/bazel/releases/download/$VER

dl()
{
    OS=$1
    PLATFORM=$2
    SUFFIX=${3:-}
    URL=$MIRROR/bazel-$VER-installer-$OS-$PLATFORM.sh.sha256
    curl -SsL $URL
}

dl linux x86_64
dl darwin x86_64

