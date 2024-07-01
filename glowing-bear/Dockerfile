FROM node:alpine AS builder
WORKDIR /app

ENV GLOWING_BEAR_COMMIT=52b1aa0228bbc16c6752403fd516cf3b140ffc59

RUN apk add --virtual=.build-deps git openssh && \
    git clone https://github.com/glowing-bear/glowing-bear glowing-bear && \
    cd glowing-bear && \
    git checkout $GLOWING_BEAR_COMMIT && \
    npm install && \
    npm run build


FROM nginx:alpine
COPY --from=builder /app/glowing-bear/build /usr/share/nginx/html
