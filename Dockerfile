# Copyright 2017-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.
#

FROM ubuntu:18.04

# Install git, SSH, and other utilities
RUN set -ex \
    && echo 'Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/99use-gzip-compression \
    && apt-get update \
    && apt-get install -y --no-install-recommends gnupg ca-certificates \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list \
    && apt-get update \
    && apt-get install software-properties-common -y --no-install-recommends \
    && apt-add-repository ppa:git-core/ppa \
    && apt-get update \
    && apt-get install git=1:2.* -y --no-install-recommends \
    && git version \
    && apt-get install -y --no-install-recommends openssh-client=1:7.6* \
    && mkdir ~/.ssh \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && DEBIAN_FRONTEND="noninteractive" TZ="Europe/London" apt-get install -y --no-install-recommends \
       sudo=1.8.* wget=1.19.4-* python=2.7.* python2.7-dev=2.7.* fakeroot=1.22-* \
       tar=1.29b-* gzip=1.6-* zip=3.0-* autoconf=2.69-* automake=1:1.15.* \
       bzip2=1.0.* file=1:5.32-* g++=4:7.4.* gcc=4:7.4.* imagemagick=8:6.9.* \
       libbz2-dev=1.0.* libc6-dev=2.27-* libcurl4-openssl-dev=7.58.* libdb-dev=1:5.3.* \
       libevent-dev=2.1.* libffi-dev=3.2.* libgeoip-dev=1.6.* libglib2.0-dev=2.56.* \
       libjpeg-dev=8c-* libkrb5-dev=1.16-* liblzma-dev=5.2.* \
       libmagickcore-dev=8:6.9.* libmagickwand-dev=8:6.9.* libmysqlclient-dev=5.7.* \
       libncurses5-dev=6.1-* libpng-dev=1.6.* libpq5=10.22-* libpq-dev=10.22-* libreadline-dev=7.0-* \
       libsqlite3-dev=3.22.* libssl-dev=1.1.* libtool=2.4.* libwebp-dev=0.6.* \
       libxml2-dev=2.9.* libxslt1-dev=1.1.* libyaml-dev=0.1.* make=4.1-* \
       patch=2.7.* xz-utils=5.2.* zlib1g-dev=1:1.2.* unzip=6.0-* curl=7.58.* \
       e2fsprogs=1.44.* iptables=1.6.* xfsprogs=4.9.* xz-utils=5.2.* \
       mono-devel less=487-* groff=1.22.* liberror-perl=0.17025-* \
       asciidoc=8.6.* build-essential=12.* bzr=2.7.* cvs=2:1.12.* cvsps=2.1-* docbook-xml=4.5-* docbook-xsl=1.79.* dpkg-dev=1.19.* \
       libdbd-sqlite3-perl=1.56-* libdbi-perl=1.640-* libdpkg-perl=1.19.* libhttp-date-perl=6.02-* \
       libio-pty-perl=1:1.08-* libserf-1-1=1.3.* libsvn-perl=1.9.* libsvn1=1.9.* libtcl8.6=8.6.* libtimedate-perl=2.3000-* \
       libunistring2=0.9.* libxml2-utils=2.9.* libyaml-perl=1.24-* python-bzrlib=2.7.* python-configobj=5.0.* \
       sgml-base=1.29 sgml-data=2.0.* subversion=1.9.* tcl=8.6.* tcl8.6=8.6.* xml-core=0.18* xmlto=0.0.* xsltproc=1.1.* \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Download and set up GitVersion
ENV GITVERSION_VERSION="5.3.5"

RUN set -ex \
    && wget "https://github.com/GitTools/GitVersion/archive/refs/tags/${GITVERSION_VERSION}.zip" -O /tmp/GitVersion_${GITVERSION_VERSION}.zip \
    && mkdir -p /usr/local/GitVersion_${GITVERSION_VERSION} \
    && unzip /tmp/GitVersion_${GITVERSION_VERSION}.zip -d /usr/local/GitVersion_${GITVERSION_VERSION} \
    && rm /tmp/GitVersion_${GITVERSION_VERSION}.zip \
    && echo "mono /usr/local/GitVersion_${GITVERSION_VERSION}/GitVersion.exe \$@" >> /usr/local/bin/gitversion \
    && chmod +x /usr/local/bin/gitversion

# Install Docker
ENV DOCKER_BUCKET="download.docker.com" \
    DOCKER_VERSION="20.10.8" \
    DOCKER_CHANNEL="stable" \
    DOCKER_SHA256="7ea11ecb100fdc085dbfd9ab1ff380e7f99733c890ed815510a5952e5d6dd7e0" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034" \
    DOCKER_COMPOSE_VERSION="1.26.0"

RUN set -ex \
    && curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin/ \
    && rm docker.tgz \
    && docker -v \
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
    && addgroup dockremap \
    && useradd -g dockremap dockremap \
    && echo 'dockremap:165536:65536' >> /etc/subuid \
    && echo 'dockremap:165536:65536' >> /etc/subgid \
    && wget "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" -O /usr/local/bin/dind \
    && curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/dind /usr/local/bin/docker-compose \
# Ensure docker-compose works
    && docker-compose version

# Install dependencies by all python images equivalent to buildpack-deps:jessie
# on the public repos.

RUN set -ex \
    && wget "https://bootstrap.pypa.io/pip/2.6/get-pip.py" -O /tmp/get-pip.py \
    && python /tmp/get-pip.py \
    && pip install awscli==1.* \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /var/lib/docker

COPY dockerd-entrypoint.sh /usr/local/bin/
