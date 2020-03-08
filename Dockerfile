FROM node:12
MAINTAINER Jessica Smith <jess@mintopia.net

EXPOSE 8080

ENV \
    CLUSTERIO_VERSION=1.2.4 \
    CLUSTERIO_MASTER_AUTH_SECRET=

RUN \
    wget -O /tmp/clusterio.tar.gz https://github.com/clusterio/factorioClusterio/archive/${CLUSTERIO_VERSION}.tar.gz && \
    tar -zxf /tmp/clusterio.tar.gz -C /opt && \
    mv /opt/factorioClusterio-${CLUSTERIO_VERSION} /opt/clusterio/ && \
    rm /tmp/clusterio.tar.gz && \
    chdir /opt/clusterio && \
    npm install --only=production && \
    node lib/npmPostinstall.js

COPY overlay /

WORKDIR /opt/clusterio

ENTRYPOINT ["/bin/bash", "clusterio.sh"]
CMD ["node", "master.js"]
