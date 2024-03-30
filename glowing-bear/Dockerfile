FROM node:alpine AS builder
WORKDIR /app

ENV GLOWING_BEAR_COMMIT=5a494a007f8e655459cdeb5f4a5bf805dd89a895

RUN apk add --virtual=.build-deps git openssh && \
    git clone https://github.com/glowing-bear/glowing-bear glowing-bear && \
    cd glowing-bear && \
    git checkout $GLOWING_BEAR_COMMIT && \
    npm install && \
    npm run build


FROM nginx:alpine
COPY --from=builder /app/glowing-bear/build /usr/share/nginx/html
