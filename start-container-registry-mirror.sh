#!/usr/bin/env bash
set -euo pipefail

REGISTRY_PORT=5000
REGISTRY_DIR=$HOME/.registry/docker.io
REGISTRY_NAME=registry-docker
REGISTRY_PROXY=https://index.docker.io
USERNAME=
PASSWORD=

OPTS=$(getopt -o '' --long 'port:,dir:,name:,proxy:,username:,password:' -- "$@")
eval set -- "$OPTS"
unset OPTS

while true ; do
    case "$1" in
        '--port')
            REGISTRY_PORT="$2"
            shift 2
            continue
            ;;
        '--dir')
            REGISTRY_DIR="$2"
            shift 2
            continue
            ;;
        '--name')
            REGISTRY_NAME="$2"
            shift 2
            continue
            ;;
        '--proxy')
            REGISTRY_PROXY="$2"
            shift 2
            continue
            ;;
        '--username')
            USERNAME="$2"
            shift 2
            continue
            ;;
        '--password')
            PASSWORD="$2"
            shift 2
            continue
            ;;
        '--')
            shift
            break
            ;;
        *)
            echo 'Internal error!' >&2
            exit 1
            ;;
    esac
done

if curl --fail --silent "http://localhost:${REGISTRY_PORT}/"; then
  echo "Local registry is already running"
  exit 0
fi

mkdir -p "${REGISTRY_DIR}"
cat <<EOF >"${REGISTRY_DIR}/config.yml"
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
proxy:
  remoteurl: ${REGISTRY_PROXY}
EOF

if [[ -n ${USERNAME:-} ]] && [[ -n ${PASSWORD:-} ]]; then
  cat <<EOF >>"${REGISTRY_DIR}/config.yml"
  username: "${USERNAME}"
  password: "${PASSWORD}"
EOF
fi

echo "Starting registry on port ${REGISTRY_PORT} ${REGISTRY_DIR}"

docker run --network kind -d --restart=always -p "${REGISTRY_PORT}":5000 --name "${REGISTRY_NAME}" -v "${REGISTRY_DIR}":/var/lib/registry registry:2 /var/lib/registry/config.yml
