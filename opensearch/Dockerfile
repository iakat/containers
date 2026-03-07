ARG OPENSEARCH_VERSION=2.19.0

FROM ibm-semeru-runtimes:open-21-jdk-jammy AS semeru

FROM opensearchproject/opensearch:${OPENSEARCH_VERSION}

USER root

RUN rm -rf /usr/share/opensearch/jdk
COPY --from=semeru /opt/java/openjdk /usr/share/opensearch/jdk
RUN chown -R opensearch:opensearch /usr/share/opensearch/jdk

# Remove plugins that invoke the broken HotSpot CLI chain and aren't needed
RUN /usr/share/opensearch/bin/opensearch-plugin remove opensearch-performance-analyzer && \
    /usr/share/opensearch/bin/opensearch-plugin remove opensearch-security && \
    /usr/share/opensearch/bin/opensearch-plugin remove opensearch-security-analytics && \
    /usr/share/opensearch/bin/opensearch-plugin remove opensearch-ml-commons && \
    /usr/share/opensearch/bin/opensearch-plugin remove opensearch-anomaly-detection && \
    /usr/share/opensearch/bin/opensearch-plugin remove opensearch-alerting && \
    /usr/share/opensearch/bin/opensearch-plugin remove opensearch-notifications && \
    /usr/share/opensearch/bin/opensearch-plugin remove opensearch-notifications-core && \
    /usr/share/opensearch/bin/opensearch-plugin remove opensearch-reports-scheduler && \
    /usr/share/opensearch/bin/opensearch-plugin remove opensearch-cross-cluster-replication || true

ENV OPENSEARCH_JAVA_HOME=/usr/share/opensearch/jdk
ENV JAVA_HOME=/usr/share/opensearch/jdk
ENV PATH="/usr/share/opensearch/jdk/bin:${PATH}"

COPY entrypoint.sh /usr/share/opensearch/entrypoint.sh
RUN chmod +x /usr/share/opensearch/entrypoint.sh && \
    chown opensearch:opensearch /usr/share/opensearch/entrypoint.sh

# Per-deployment, set OPENSEARCH_JAVA_OPTS in your k8s manifest:
# -Xms256m -Xmx512m -Xsoftmx256m -XX:MaxDirectMemorySize=128m

USER opensearch

RUN java -version 2>&1 | grep -i "openj9" || exit 1

CMD ["/usr/share/opensearch/entrypoint.sh"]
