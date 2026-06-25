FROM ghcr.io/gohugoio/hugo:v0.163.3 AS builder

ARG REPO_URL
ARG REPO_BRANCH

# hadolint ignore=DL3002
USER root

# hadolint ignore=DL3018
RUN apk add --no-cache git openssh

RUN --mount=type=secret,id=git_ssh_key \
    mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts && \
    git config --global core.sshCommand 'ssh -i /run/secrets/git_ssh_key' && \
    git clone --branch "${REPO_BRANCH}" --depth 1 --recursive "${REPO_URL}" /src && \
    hugo --minify --source /src

FROM reg.mini.dev/caddy:2.11.4

COPY --from=builder /src/public /srv

CMD ["caddy", "file-server"]