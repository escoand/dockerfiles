FROM docker.io/library/alpine:3.23.2

# hadolint ignore=DL3008
RUN apk add --no-cache curl jq msmtp

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]
