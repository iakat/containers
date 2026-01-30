FROM alpine:3.20 AS builder

ARG SOLRWAYBACK_VERSION=5.1.2

RUN apk add --no-cache wget unzip

WORKDIR /build

RUN wget -q "https://github.com/netarchivesuite/solrwayback/releases/download/${SOLRWAYBACK_VERSION}/solrwayback_package_${SOLRWAYBACK_VERSION}.zip" -O bundle.zip && \
    unzip -q bundle.zip && \
    rm bundle.zip && \
    mv "solrwayback_package_${SOLRWAYBACK_VERSION}" solrwayback

FROM amazoncorretto:17-alpine

ENV SOLRWAYBACK_VERSION=5.1.2 \
    APACHE_TOMCAT_VERSION=9 \
    SOLR_VERSION=9 \
    SOLRWAYBACK_HOME=/opt/solrwayback

RUN apk add --no-cache lsof curl bc procps && \
    adduser -D -s /bin/sh solrwayback && \
    mkdir -p ${SOLRWAYBACK_HOME}

COPY --from=builder --chown=solrwayback:solrwayback /build/solrwayback ${SOLRWAYBACK_HOME}

USER solrwayback
WORKDIR /home/solrwayback

RUN cp ${SOLRWAYBACK_HOME}/properties/solrwayback.properties . && \
    cp ${SOLRWAYBACK_HOME}/properties/solrwaybackweb.properties .

EXPOSE 8080 8983

CMD ["/bin/sh"]
