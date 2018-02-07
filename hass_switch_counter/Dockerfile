ARG ARCH=armhf

FROM multiarch/alpine:$ARCH-latest-stable

RUN apk --no-cache add py-rpigpio py-paho-mqtt

COPY entrypoint.py /root/entrypoint.py

ENTRYPOINT /root/entrypoint.py
