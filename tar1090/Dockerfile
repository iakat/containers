FROM nginx:alpine
WORKDIR /opt/tar1090
COPY html .
COPY nginx.conf /etc/nginx/tar1090.conf
RUN set -ex && \
    apk add --virtual=.build-deps git sed && \
    mkdir -p /opt/tar1090-db && \
    wget -qO- https://github.com/katlol/tar1090-db/releases/latest/download/db.tar | tar -C /opt/tar1090-db -xvf - && \
    ln -s /opt/tar1090-db/db /opt/tar1090/db2 && \
    sed -i'' "s/INSTANCE\///" /etc/nginx/tar1090.conf && \
    sed -i'' "s/\/INSTANCE/\//" /etc/nginx/tar1090.conf && \
    sed -i'' 's/\/SERVICE/\/readsb/' /etc/nginx/tar1090.conf && \
    sed -i'' 's/SOURCE_DIR\//\/run\/readsb\//' /etc/nginx/tar1090.conf && \
    sed -i'' 's/HTMLPATH\//\/opt\/tar1090\//' /etc/nginx/tar1090.conf && \
    echo "server {listen 80;listen [::]:80;server_name _;include /etc/nginx/tar1090.conf;}" > /etc/nginx/conf.d/default.conf && \
    nginx -t && \
    apk del .build-deps
