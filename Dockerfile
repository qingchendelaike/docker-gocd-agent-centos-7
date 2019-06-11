# Copyright 2018 ThoughtWorks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################################
# This file is autogenerated by the repository at https://github.com/gocd/docker-gocd-agent.
# Please file any issues or PRs at https://github.com/gocd/docker-gocd-agent
###############################################################################################

FROM alpine:latest as gocd-agent-unzip
RUN \
  apk --no-cache upgrade && \
  apk add --no-cache curl && \
  curl --fail --location --silent --show-error "https://download.gocd.org/binaries/19.5.0-9272/generic/go-agent-19.5.0-9272.zip" > /tmp/go-agent-19.5.0-9272.zip

RUN unzip /tmp/go-agent-19.5.0-9272.zip -d /
RUN mv /go-agent-19.5.0 /go-agent

FROM centos:7
MAINTAINER ThoughtWorks, Inc. <support@thoughtworks.com>

LABEL gocd.version="19.5.0" \
  description="GoCD agent based on centos version 7" \
  maintainer="ThoughtWorks, Inc. <support@thoughtworks.com>" \
  url="https://www.gocd.org" \
  gocd.full.version="19.5.0-9272" \
  gocd.git.sha="496bf8b95e603c1f3980ae59042bc559eecbbbc0"

ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini-static-amd64 /usr/local/sbin/tini
ADD https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64 /usr/local/sbin/gosu

# force encoding
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV GO_JAVA_HOME="/gocd-jre"
ENV BASH_ENV="/opt/rh/rh-git29/enable"
ENV ENV="/opt/rh/rh-git29/enable"

ARG UID=1000
ARG GID=1000

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
  chmod 0755 /usr/local/sbin/gosu && \
  chown root:root /usr/local/sbin/gosu && \
# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
  groupadd -g ${GID} go && \
  useradd -u ${UID} -g go -d /home/go -m go && \
  yum update -y && \
  yum install -y mercurial subversion openssh-clients bash unzip curl && \
  yum install --assumeyes centos-release-scl && \
  yum install --assumeyes rh-git29 && \
  cp /opt/rh/rh-git29/enable /etc/profile.d/rh-git29.sh && \
  yum clean all && \
  curl --fail --location --silent --show-error 'https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk-12.0.1%2B12/OpenJDK12U-jre_x64_linux_hotspot_12.0.1_12.tar.gz' --output /tmp/jre.tar.gz && \
  mkdir -p /gocd-jre && \
  tar -xf /tmp/jre.tar.gz -C /gocd-jre --strip 1 && \
  rm -rf /tmp/jre.tar.gz && \
  mkdir -p /docker-entrypoint.d

COPY --from=gocd-agent-unzip /go-agent /go-agent
# ensure that logs are printed to console output
COPY agent-bootstrapper-logback-include.xml agent-launcher-logback-include.xml agent-logback-include.xml /go-agent/config/

ADD docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
