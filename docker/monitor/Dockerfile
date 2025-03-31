FROM alpine

RUN apk add --no-cache curl jq msmtp

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]
