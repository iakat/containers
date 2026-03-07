ARG OPENSEARCH_VERSION=2.19.0

FROM ibm-semeru-runtimes:open-21-jdk-jammy AS semeru

FROM opensearchproject/opensearch:${OPENSEARCH_VERSION}

USER root

RUN rm -rf /usr/share/opensearch/jdk
COPY --from=semeru /opt/java/openjdk /usr/share/opensearch/jdk
RUN chown -R opensearch:opensearch /usr/share/opensearch/jdk

# Strip ALL HotSpot-specific flags from jvm.options (including version-gated ones like 11-:-XX:+UseG1GC)
RUN sed -i \
    -e '/UseG1GC/d' \
    -e '/G1ReservePercent/d' \
    -e '/InitiatingHeapOccupancyPercent/d' \
    -e '/UseConcMarkSweepGC/d' \
    -e '/CMSInitiatingOccupancyFraction/d' \
    -e '/UseCMSInitiatingOccupancyOnly/d' \
    -e '/UseSerialGC/d' \
    -e '/CICompilerCount/d' \
    -e '/TieredCompilation/d' \
    -e '/InitialCodeCacheSize/d' \
    -e '/InitialBootClassLoaderMetaspaceSize/d' \
    -e '/-Xlog:/d' \
    /usr/share/opensearch/config/jvm.options

# Also strip UseSerialGC from CLI tool scripts (opensearch-env, opensearch-cli, etc.)
RUN find /usr/share/opensearch/bin -type f -name "*.sh" -exec sed -i 's/-XX:+UseSerialGC//g' {} + 2>/dev/null; \
    find /usr/share/opensearch/bin -type f ! -name "*.sh" -exec sed -i 's/-XX:+UseSerialGC//g' {} + 2>/dev/null; \
    true

ENV OPENSEARCH_JAVA_HOME=/usr/share/opensearch/jdk
ENV JAVA_HOME=/usr/share/opensearch/jdk
ENV PATH="/usr/share/opensearch/jdk/bin:${PATH}"

# Don't include -Xgcpolicy:gencon here — it's already the OpenJ9 default,
# and putting a GC policy in OPENSEARCH_JAVA_OPTS conflicts with CLI tools
ENV OPENJ9_BASE_OPTS="-XX:+IdleTuningGcOnIdle -XX:IdleTuningMinIdleWaitTime=240 -Xshareclasses:none -Xquickstart -Xmns8m -Xmnx64m -Xsoftrefthreshold1 -XX:+ExitOnOutOfMemoryError"

RUN sed -i '1a export OPENSEARCH_JAVA_OPTS="${OPENJ9_BASE_OPTS} ${OPENSEARCH_JAVA_OPTS}"' \
    /usr/share/opensearch/opensearch-docker-entrypoint.sh

# Per-deployment, set OPENSEARCH_JAVA_OPTS in your k8s manifest:
# -Xms256m -Xmx512m -Xsoftmx256m -XX:MaxDirectMemorySize=128m

USER opensearch

RUN java -version 2>&1 | grep -i "openj9" || exit 1
