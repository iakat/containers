FROM alpine:edge
RUN apk add --no-cache --virtual=.run-deps nginx nginx-mod-http-fancyindex
ENTRYPOINT ["nginx", "-g", "daemon off;"]
