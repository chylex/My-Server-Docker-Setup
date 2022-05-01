#!/usr/bin/env sh

cp /app/proxy.conf /app/ssl.conf /etc/nginx/conf.d/

env() {
  eval VALUE="\$$1"
  sed -i 's|{'"$1"'}|'"$VALUE"'|' "/etc/nginx/conf.d/$2"
}

INCLUDES=""
LISTEN=""

if [ -n "SSL_CERT" ] && [ -n "$SSL_CERT_KEY" ]; then
  INCLUDES="include conf.d/ssl.conf;"
  LISTEN=" ssl"
  env SSL_CERT      ssl.conf
  env SSL_CERT_KEY  ssl.conf
fi

env SERVER_NAME  proxy.conf
env SERVER_PORT  proxy.conf
env UPSTREAM     proxy.conf
env INCLUDES     proxy.conf
env LISTEN       proxy.conf

nginx -g 'daemon off;'
