FROM node:alpine AS builder
WORKDIR /app

ENV GLOWING_BEAR_COMMIT=f39fe804b10b407f00467c8455772e9ce4ba95cf

RUN apk add --virtual=.build-deps git openssh && \
    git clone https://github.com/iakat/glowing-bear glowing-bear && \
    cd glowing-bear && \
    npm install && \
    npm run build


FROM nginx:alpine
COPY --from=builder /app/glowing-bear/build /usr/share/nginx/html
