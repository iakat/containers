FROM python:3-alpine

RUN apk add \
    bash jq kubectl \
    curl wget openssh-client git \
    ca-certificates rsync && \
    pip install --no-cache-dir aiohttp requests
