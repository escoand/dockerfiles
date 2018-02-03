ARG  ARCH=amd64

FROM multiarch/alpine:$ARCH-latest-stable

RUN  apk --no-cache add mosquitto-clients bluez-deprecated

COPY entrypoint.sh /root/entrypoint.sh

ENTRYPOINT /root/entrypoint.sh
