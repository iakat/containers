FROM python:3-alpine

RUN apk add --no-cache --virtual=.build-deps build-base && \
    pip install --no-cache-dir pip-tools poetry pipx pipenv && \
    apk del .build-deps
