#!/bin/sh

set -e

htpasswd -bc /etc/nginx/htpasswd git "${BOOTSTRAP_GIT_PASSWORD:-}"

service fcgiwrap start
