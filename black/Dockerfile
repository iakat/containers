FROM python:3-alpine

RUN apk add --no-cache --virtual=.build-deps build-base && \
    pip install --no-cache-dir black && \
    apk del .build-deps
