FROM docker.io/library/alpine:3.23.2

# hadolint ignore=DL3018
RUN apk add --no-cache curl jq msmtp uuidgen

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]
