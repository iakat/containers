FROM python:3.12-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libffi-dev libssl-dev tini && \
    pip install --no-cache-dir warcprox && \
    apt-get purge -y gcc libffi-dev libssl-dev && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -m -s /bin/sh warcprox && \
    mkdir -p /data && \
    chown warcprox:warcprox /data

USER warcprox
WORKDIR /data

EXPOSE 8000

ENTRYPOINT ["tini", "--"]
CMD ["warcprox", "-b", "0.0.0.0", "-d", "/data"]
