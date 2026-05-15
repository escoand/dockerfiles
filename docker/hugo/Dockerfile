FROM docker.io/hugomods/hugo AS builder

ARG REPO_URL

RUN apk add --no-cache git openssh

RUN --mount=type=secret,id=git_ssh_key \
    set -x && \
    mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts && \
    git config --global core.sshCommand 'ssh -i /run/secrets/git_ssh_key' && \
    git clone --depth 1 --recursive ${REPO_URL} /src && \
    hugo --minify --source /src

FROM docker.io/caddy:alpine

COPY --from=builder /src/public /srv

CMD ["caddy", "file-server"]