#!/bin/bash
set -e

BASE=/app/.images

if [[ "$1" == "" ]] || [[ "$1" == "nginx-proxy" ]]; then
  echo "Building local/nginx-proxy..."
  docker build --pull -t local/nginx-proxy "$BASE/nginx-proxy"
fi

if [[ "$1" == "" ]] || [[ "$1" == "db-backup" ]]; then
  echo "Building local/db-backup..."
  docker build --pull -t local/db-backup "$BASE/db-backup"
fi

echo "Done!"
