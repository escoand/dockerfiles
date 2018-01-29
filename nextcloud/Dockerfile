FROM nextcloud:fpm

RUN apt-get update && apt-get install -y \
  supervisor \
  cron \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/log/supervisord /var/run/supervisord && \ 
  echo "*/15 * * * * su - www-data -s /bin/bash -c \"php -f /var/www/html/cron.php\""| crontab -
  printf '*/15 * * * * su - www-data -s /bin/sh -c \"php -f /var/www/html/cron.php\"\n5 */2 * * * su - www-data -s /bin/sh -c \"php -f /var/www/html/occ files:scan --all\"\n35 */2 * * * su - www-data -s /bin-sh -c \"php /var/www/html/occ preview:pre-generate\"\n' | crontab -

COPY supervisord.conf /etc/supervisor/supervisord.conf

CMD ["/usr/bin/supervisord"]
