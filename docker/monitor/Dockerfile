FROM docker.io/library/alpine:3.22.2

RUN apk add --no-cache curl jq msmtp

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]
