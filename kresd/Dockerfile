FROM alpine
RUN apk add --no-cache --virtual=.run-deps kresd tini
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["kresd", "-a"]
