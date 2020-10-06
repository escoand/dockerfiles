FROM debian:stable-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        g++ \
        git \
        libqtav-dev \
        make \
        qt5-default \
        qtwebengine5-dev \
    && cd /tmp \
    && git clone https://github.com/sagiadinos/garlic-player.git \
    && cd garlic-player \
    && mkdir build \
    && cd build \
    && qmake ../src/complete.pro \
    && make

FROM debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        libqt5webengine5 \
        libqt5webenginewidgets5 \
        libqtav1 \
        libqtavwidgets1 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/garlic-player/build/bin/* /usr/bin/
COPY --from=builder /tmp/garlic-player/build/lib/* /usr/lib/

CMD sh -c 'garlic-player $SMIL_URL'
