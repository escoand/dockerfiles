FROM alpine

RUN apk add --no-cache jq mosquitto-clients smartmontools

ADD check.sh /

CMD sh -x /check.sh
