ARG OPENSEARCH_VERSION=2.19.0

FROM ibm-semeru-runtimes:open-21-jdk-jammy AS semeru

FROM opensearchproject/opensearch:${OPENSEARCH_VERSION}

USER root

RUN rm -rf /usr/share/opensearch/jdk
COPY --from=semeru /opt/java/openjdk /usr/share/opensearch/jdk
RUN chown -R opensearch:opensearch /usr/share/opensearch/jdk

RUN sed -i \
    -e '/-Xlog:/d' \
    -e '/-XX:+UseG1GC/d' \
    -e '/-XX:G1ReservePercent/d' \
    -e '/-XX:InitiatingHeapOccupancyPercent/d' \
    -e '/-XX:+UseSerialGC/d' \
    -e '/-XX:CICompilerCount/d' \
    -e '/-XX:-TieredCompilation/d' \
    -e '/-XX:InitialCodeCacheSize/d' \
    -e '/-XX:InitialBootClassLoaderMetaspaceSize/d' \
    /usr/share/opensearch/config/jvm.options

ENV OPENSEARCH_JAVA_HOME=/usr/share/opensearch/jdk
ENV JAVA_HOME=/usr/share/opensearch/jdk
ENV PATH="/usr/share/opensearch/jdk/bin:${PATH}"

ENV OPENJ9_BASE_OPTS="-Xgcpolicy:gencon -XX:+IdleTuningGcOnIdle -XX:IdleTuningMinIdleWaitTime=240 -Xshareclasses:none -Xquickstart -Xmns8m -Xmnx64m -Xsoftrefthreshold1 -XX:+ExitOnOutOfMemoryError"

RUN sed -i '1a export OPENSEARCH_JAVA_OPTS="${OPENJ9_BASE_OPTS} ${OPENSEARCH_JAVA_OPTS}"' \
    /usr/share/opensearch/opensearch-docker-entrypoint.sh

# Per-deployment, set OPENSEARCH_JAVA_OPTS in your k8s manifest:
# -Xms256m -Xmx512m -Xsoftmx256m -XX:MaxDirectMemorySize=128m

USER opensearch

RUN java -version 2>&1 | grep -i "openj9" || exit 1
