FROM node:12 AS build

env \
    CLUSTERIO_VERSION=1.2.4

RUN apt-get update && apt-get -y upgrade && \
    apt install -y apt-utils python-dev git wget curl tar build-essential && rm -rf /var/cache/apt/* && \
    curl -o clusterio.tar.gz -L https://github.com/clusterio/factorioClusterio/archive/${CLUSTERIO_VERSION}.tar.gz && \
    tar -zxf clusterio.tar.gz && \
    mv factorioClusterio-${CLUSTERIO_VERSION} factorioClusterio && \
    cd factorioClusterio && \
    npm install --only=production && \
    node lib/npmPostinstall.js && \
    curl -o factorio.tar.xz -L https://www.factorio.com/get-download/latest/headless/linux64 && \
    tar -xvf factorio.tar.xz && \
    rm factorio.tar.xz  && \
    mkdir -p instances sharedMods sharedPlugins database/linvodb

# end build container

FROM node:12
LABEL maintainer "me@gotenxiao.co.uk"

RUN \
	apt-get update \
	&& apt-get -y install gettext-base \
	&& rm -rf /var/cache/apt/*

COPY --from=build /factorioClusterio /factorioClusterio/
WORKDIR /factorioClusterio

EXPOSE 8080

VOLUME \
    /factorioClusterio/database \
    /factorioClusterio/instances \
    /factorioClusterio/sharedMods \
    /factorioClusterio/sharedPlugins

COPY docker-entrypoint.sh /
COPY make-config.sh config.json.tmpl /factorioClusterio/
ENTRYPOINT ["/docker-entrypoint.sh"]
