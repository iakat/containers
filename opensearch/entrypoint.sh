#!/bin/bash
set -e

export OPENSEARCH_HOME=/usr/share/opensearch
export OPENSEARCH_PATH_CONF=$OPENSEARCH_HOME/config

# ---- openj9 jvm options (replaces jvm.options + JvmOptionsParser) ----
# we build the jvm flags ourselves instead of using JvmOptionsParser which
# hardcodes hotspot flags and fights openj9. we read jvm.options for the
# non-gc, non-logging lines (heap size, system properties, etc.) and
# append our openj9-specific flags.

build_jvm_opts() {
    local opts=""

    # read jvm.options, skip comments, blanks, and hotspot-specific lines
    if [ -f "$OPENSEARCH_PATH_CONF/jvm.options" ]; then
        while IFS= read -r line; do
            # skip comments and blanks
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            # skip version-gated lines (e.g. 8-10:, 11-:, 9-:)
            [[ "$line" =~ ^[0-9]+-?[0-9]*:- ]] && {
                # strip the version prefix to get the actual flag
                local flag="${line#*:-}"
                # skip all hotspot gc, gc tuning, and gc logging flags
                [[ "$flag" =~ UseG1GC|UseConcMarkSweepGC|UseSerialGC ]] && continue
                [[ "$flag" =~ G1ReservePercent|InitiatingHeapOccupancyPercent ]] && continue
                [[ "$flag" =~ CMSInitiatingOccupancyFraction|UseCMSInitiatingOccupancyOnly ]] && continue
                [[ "$flag" =~ CICompilerCount|TieredCompilation ]] && continue
                [[ "$flag" =~ InitialCodeCacheSize|InitialBootClassLoaderMetaspaceSize ]] && continue
                [[ "$flag" =~ Xlog: ]] && continue
                opts="$opts $flag"
                continue
            }
            # skip non-version-gated hotspot flags too
            [[ "$line" =~ UseG1GC|UseConcMarkSweepGC|UseSerialGC ]] && continue
            [[ "$line" =~ G1ReservePercent|InitiatingHeapOccupancyPercent ]] && continue
            [[ "$line" =~ CMSInitiatingOccupancyFraction|UseCMSInitiatingOccupancyOnly ]] && continue
            [[ "$line" =~ CICompilerCount|TieredCompilation ]] && continue
            [[ "$line" =~ InitialCodeCacheSize|InitialBootClassLoaderMetaspaceSize ]] && continue
            [[ "$line" =~ Xlog: ]] && continue
            # skip template variables that jvm.options uses (resolved by JvmOptionsParser normally)
            [[ "$line" =~ ^\$\{ ]] && continue
            opts="$opts $line"
            continue
        done < "$OPENSEARCH_PATH_CONF/jvm.options"
    fi

    # also read jvm.options.d/*.options if present
    if [ -d "$OPENSEARCH_PATH_CONF/jvm.options.d" ]; then
        for f in "$OPENSEARCH_PATH_CONF/jvm.options.d"/*.options; do
            [ -f "$f" ] || continue
            while IFS= read -r line; do
                [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
                [[ "$line" =~ UseG1GC|UseConcMarkSweepGC|UseSerialGC ]] && continue
                [[ "$line" =~ Xlog: ]] && continue
                [[ "$line" =~ ^\$\{ ]] && continue
                opts="$opts $line"
            done < "$f"
        done
    fi

    # openj9 flags
    opts="$opts -XX:+IdleTuningGcOnIdle"
    opts="$opts -XX:IdleTuningMinIdleWaitTime=240"
    opts="$opts -Xshareclasses:none"
    opts="$opts -Xquickstart"
    opts="$opts -Xmns8m"
    opts="$opts -Xmnx64m"
    opts="$opts -Xsoftrefthreshold1"
    opts="$opts -XX:+ExitOnOutOfMemoryError"

    # resolve heap dump path and error file (normally done by JvmOptionsParser)
    opts="$opts -XX:+HeapDumpOnOutOfMemoryError"
    opts="$opts -XX:HeapDumpPath=data"
    opts="$opts -XX:ErrorFile=logs/hs_err_pid%p.log"

    # tmpdir
    export OPENSEARCH_TMPDIR=$(mktemp -d -t opensearch.XXXXXXXX)
    opts="$opts -Djava.io.tmpdir=$OPENSEARCH_TMPDIR"

    # user-provided opts (from k8s env) go last so they override
    opts="$opts ${OPENSEARCH_JAVA_OPTS:-}"

    echo "$opts"
}

# ---- security plugin setup ----
setup_security() {
    local SECURITY_PLUGIN="opensearch-security"
    if [ -d "$OPENSEARCH_HOME/plugins/$SECURITY_PLUGIN" ]; then
        if [ "$DISABLE_INSTALL_DEMO_CONFIG" = "true" ]; then
            echo "Disabling execution of install_demo_configuration.sh for OpenSearch Security Plugin"
        else
            echo "Enabling execution of install_demo_configuration.sh for OpenSearch Security Plugin"
            bash "$OPENSEARCH_HOME/plugins/$SECURITY_PLUGIN/tools/install_demo_configuration.sh" -y -i -s
        fi

        if [ "$DISABLE_SECURITY_PLUGIN" = "true" ]; then
            echo "Disabling OpenSearch Security Plugin"
            opensearch_opts+=("-Eplugins.security.disabled=true")
        fi
    fi
}

# ---- performance analyzer setup ----
setup_performance_analyzer() {
    local PA_PLUGIN="opensearch-performance-analyzer"
    if [ -d "$OPENSEARCH_HOME/plugins/$PA_PLUGIN" ]; then
        if [ "$DISABLE_PERFORMANCE_ANALYZER_AGENT_CLI" = "true" ]; then
            echo "Disabling execution of performance-analyzer-agent-cli for OpenSearch Performance Analyzer Plugin"
        else
            echo "Enabling execution of performance-analyzer-agent-cli for OpenSearch Performance Analyzer Plugin"
            "$OPENSEARCH_HOME/bin/opensearch-performance-analyzer/performance-analyzer-agent-cli" \
                > "$OPENSEARCH_HOME/logs/performance-analyzer.log" 2>&1 &
            disown
        fi
    fi
}

# ---- main ----
run_opensearch() {
    local opensearch_opts=()

    # collect -E flags from environment variables
    while IFS='=' read -r envvar_key envvar_value; do
        if [[ "$envvar_key" =~ ^[a-z0-9_]+\.[a-z0-9_]+\.?[a-z0-9_]*$ ]]; then
            opensearch_opts+=("-E${envvar_key}=${envvar_value}")
        fi
    done < <(env)

    # save user's OPENSEARCH_JAVA_OPTS before cli tools clobber it
    local user_java_opts="${OPENSEARCH_JAVA_OPTS:-}"

    # cli tools (keystore, security setup) need a clean OPENSEARCH_JAVA_OPTS
    # without our openj9 flags — they use opensearch-cli which prepends its own flags
    export OPENSEARCH_JAVA_OPTS=""

    setup_security
    setup_performance_analyzer

    # now build the real jvm opts for the main opensearch process
    export OPENSEARCH_JAVA_OPTS="$user_java_opts"
    local jvm_opts
    jvm_opts=$(build_jvm_opts)

    # start opensearch directly with our jvm opts, bypassing JvmOptionsParser
    cd "$OPENSEARCH_HOME"
    exec "$OPENSEARCH_HOME/jdk/bin/java" \
        $jvm_opts \
        -Dopensearch.path.home="$OPENSEARCH_HOME" \
        -Dopensearch.path.conf="$OPENSEARCH_PATH_CONF" \
        -Dopensearch.distribution.type=docker \
        -cp "$OPENSEARCH_HOME/lib/*:$OPENSEARCH_HOME/lib/tools/launchers/*" \
        org.opensearch.bootstrap.OpenSearch \
        "${opensearch_opts[@]}"
}

if [ $# -eq 0 ] || [ "${1:0:1}" = '-' ]; then
    set -- opensearch "$@"
fi

if [ "$1" = "opensearch" ]; then
    shift
    run_opensearch "$@"
else
    exec "$@"
fi
