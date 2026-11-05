FROM alpine:3.20 AS builder

ARG SOLRWAYBACK_VERSION=5.5.0
ARG SOLRWAYBACK_SHA256=f1902ca6923eed98f1478c5df7daadea4f4fd132dd5332226b3515b16aa27c8d

RUN apk add --no-cache wget unzip coreutils

WORKDIR /build

RUN wget -q "https://github.com/netarchivesuite/solrwayback/releases/download/${SOLRWAYBACK_VERSION}/solrwayback_package_${SOLRWAYBACK_VERSION}.zip" -O bundle.zip && \
    echo "${SOLRWAYBACK_SHA256}  bundle.zip" | sha256sum -c - && \
    unzip -q bundle.zip && \
    rm bundle.zip && \
    mv "solrwayback_package_${SOLRWAYBACK_VERSION}" solrwayback

# Build the WAR from source so the nanosecond WARC-Date fix is included.
FROM maven:3.9-eclipse-temurin-17 AS war

ARG SOLRWAYBACK_VERSION=5.5.0

RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${SOLRWAYBACK_VERSION}" \
        https://github.com/netarchivesuite/solrwayback.git /src

COPY nanoseconds.patch /tmp/nanoseconds.patch

RUN cd /src && \
    git apply /tmp/nanoseconds.patch && \
    mvn -q -Dmaven.test.skip=true package

FROM amazoncorretto:17-alpine

ARG SOLRWAYBACK_VERSION=5.5.0
ENV SOLRWAYBACK_VERSION=${SOLRWAYBACK_VERSION} \
    APACHE_TOMCAT_VERSION=9 \
    SOLR_VERSION=9 \
    SOLRWAYBACK_HOME=/opt/solrwayback \
    SOLR_HOME=/var/solr \
    SOLR_LOGS_DIR=/var/solr/logs \
    CATALINA_HOME=/opt/solrwayback/tomcat-9 \
    CATALINA_BASE=/opt/solrwayback/tomcat-9

RUN apk add --no-cache bash lsof curl bc procps tini && \
    adduser -D -s /bin/sh solrwayback && \
    mkdir -p ${SOLRWAYBACK_HOME}

COPY --from=builder --chown=solrwayback:solrwayback /build/solrwayback ${SOLRWAYBACK_HOME}

# Replace the bundle WAR with the patched source build.
COPY --from=war --chown=solrwayback:solrwayback \
    /src/target/solrwayback-${SOLRWAYBACK_VERSION}.war \
    ${SOLRWAYBACK_HOME}/tomcat-9/webapps/solrwayback.war

# Keep only the /solrwayback context. ROOT.war is the optional root servlet and
# conflicts with the oauth2-proxy front door we use.
RUN rm -rf ${SOLRWAYBACK_HOME}/tomcat-9/webapps/ROOT \
           ${SOLRWAYBACK_HOME}/tomcat-9/webapps/ROOT.war && \
    sed -i 's/maxThreads="200"/maxThreads="50"/' ${SOLRWAYBACK_HOME}/tomcat-9/conf/server.xml && \
    sed -i 's/-Xmx1024M/-Xmx${INDEXER_MEM:-768M}/g' ${SOLRWAYBACK_HOME}/indexing/warc-indexer.sh && \
    mkdir -p /var/solr/logs && \
    chown -R solrwayback:solrwayback /var/solr

USER solrwayback
WORKDIR /home/solrwayback

RUN cp ${SOLRWAYBACK_HOME}/properties/solrwayback.properties . && \
    cp ${SOLRWAYBACK_HOME}/properties/solrwaybackweb.properties .

EXPOSE 8080 8983

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/sh"]
