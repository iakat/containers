FROM alpine
RUN apk add --no-cache --virtual=.run-deps knot-resolver tini
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/sbin/kresd", "-a"]
