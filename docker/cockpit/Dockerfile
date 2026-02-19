FROM docker.io/alpine AS builder

RUN wget \
        https://github.com/cockpit-project/cockpit-files/releases/download/36/cockpit-files-36.tar.xz \
        https://github.com/cockpit-project/cockpit-podman/releases/download/121/cockpit-podman-121.tar.xz && \
    tar -xf cockpit-files-*.tar.xz && \
    tar -xf cockpit-podman-*.tar.xz

FROM quay.io/cockpit/ws:356

COPY --from=builder /cockpit-files/dist /usr/share/cockpit/files
COPY --from=builder /cockpit-podman/dist /usr/share/cockpit/podman