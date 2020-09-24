FROM alpine

RUN apk add --no-cache mosquitto-clients smartmontools

ADD check.sh /

CMD sh /check.sh
