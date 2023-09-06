FROM python:3-alpine

RUN apk add --no-cache --virtual=.build-deps build-base && \
    pip install --no-cache-dir pip-tools && \
    apk del .build-deps
