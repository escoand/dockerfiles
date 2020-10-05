FROM debian:stable-slim AS builder

RUN apt update \
    && apt upgrade \
    && apt install \
           libqtav-dev \
           git \
           qt5-default \
           qtwebengine5-dev \
           g++ \
           make \
    && cd /tmp \
    && git clone https://github.com/sagiadinos/garlic-player \
    && cd garlic-player \
    && mkdir build \
    && cd build \
    && qmake ../src/complete.pro \
    && make

FROM debian:stable-slim

COPY --from=builder /tmp/garlic-player/build/bin/* /usr/local/bin/
COPY --from=builder /tmp/garlic-player/build/lib/* /usr/local/lib/

CMD sh -c 'garlic-player $SMIL_URL'
