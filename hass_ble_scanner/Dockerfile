ARG  TAG=amd64-latest-stable

FROM multiarch/alpine:$TAG

RUN  apk --no-cache add mosquitto-clients bluez-deprecated

COPY entrypoint.sh /root/entrypoint.sh

ENTRYPOINT /root/entrypoint.sh
