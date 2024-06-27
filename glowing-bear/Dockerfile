FROM node:alpine AS builder
WORKDIR /app

ENV GLOWING_BEAR_COMMIT=31b020aec0d258629594c8e26eed5cecae9be236

RUN apk add --virtual=.build-deps git openssh && \
    git clone https://github.com/iakat/glowing-bear glowing-bear && \
    cd glowing-bear && \
    git checkout $GLOWING_BEAR_COMMIT && \
    npm install && \
    npm run build


FROM nginx:alpine
COPY --from=builder /app/glowing-bear/build /usr/share/nginx/html
