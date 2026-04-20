podman run --rm -it \
  --label 'caddy=matrix.{$WORDPRESS1_DOMAIN}' \
  --label 'caddy.reverse_proxy={{upstreams}}' \
  -e PMA_HOST=mariadb \
  --network podman \
  --network systemd-backend \
  -p 8080:80 phpmyadmin
