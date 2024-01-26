FROM alpine:edge
# add testing repo
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add soju
CMD ["/usr/bin/soju"]
