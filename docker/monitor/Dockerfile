FROM docker.io/library/alpine:3.22.1

RUN apk add --no-cache curl jq msmtp

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]
