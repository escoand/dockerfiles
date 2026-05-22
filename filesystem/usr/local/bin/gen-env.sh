#!/bin/sh
# Creates ~/.config/notify-fail.env from podman secrets.

set -e

ENV_FILE="$HOME/.config/notify-fail.env"

# Read all EVENTS_* secrets from podman into the environment
eval "$(
    podman secret ls |
        grep -ow 'EVENTS_[A-Z_]*' |
        xargs podman secret inspect --showsecret |
        jq -r '.[] | (.Spec.Name + "=" + (.SecretData | @sh))'
)"

# Login with credentials to get a fresh access token
MATRIX_HOST="https://$EVENTS_MATRIX_DOMAIN"
MATRIX_ACCESS_TOKEN=$(
    curl -fsS \
        -H 'Content-Type: application/json' \
        -d "{\"type\":\"m.login.password\",\"user\":\"$EVENTS_MATRIX_USER\",\"password\":\"$EVENTS_MATRIX_PASSWORD\"}" \
        "$MATRIX_HOST/_matrix/client/r0/login" |
        jq -r '.access_token'
)

if [ -z "$MATRIX_ACCESS_TOKEN" ] || [ "$MATRIX_ACCESS_TOKEN" = "null" ]; then
    echo "ERROR: Matrix login failed" >&2
    exit 1
fi

mkdir -p "$(dirname "$ENV_FILE")"
cat >"$ENV_FILE" <<EOF
MATRIX_HOST=$MATRIX_HOST
MATRIX_ACCESS_TOKEN=$MATRIX_ACCESS_TOKEN
MATRIX_ROOM_ID=$EVENTS_ROOM_ID
EOF

chmod 600 "$ENV_FILE"
echo "Written: $ENV_FILE"
