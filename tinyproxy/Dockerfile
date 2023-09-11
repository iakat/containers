FROM alpine
RUN apk add --no-cache tinyproxy
COPY tinyproxy.conf /etc/tinyproxy/tinyproxy.conf
EXPOSE 8888
CMD ["tinyproxy", "-d"]
