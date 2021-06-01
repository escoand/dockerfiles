#!/bin/sh

FILES=""
BASEDIR=$(dirname "$0")
cd "$BASEDIR"

git pull --all &&
sudo sh -c "
	docker-compose $FILES pull --no-parallel &&
	docker-compose $FILES up -d &&
	docker system prune -af
"
