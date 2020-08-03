FROM alpine:edge

LABEL maintainer="Zalgo Noise <zalgo.noise@gmail.com>"
LABEL version="1.0"
LABEL description="G Suite LDAP Query Docker image. Built for testing access to your domain via SLDAP, through G Suite's parameters."

RUN apk add \
    --update \
    --no-cache \
    stunnel \
    libressl \
    openldap-clients \
    unzip

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
