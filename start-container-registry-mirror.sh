#!/usr/bin/env bash

#############################################################################
# start-container-registry-mirror.sh
#
# starts a docker container providing a container registry mirror
#
# This scripts is useful when creating many Kind Kubernetes clusters in a
# short period of time e.g. as part of your day-to-day activities. In those
# cases you start a Docker container providing a registry mirror for
# docker.io and let kind make use of that (see kind-with-custom-registry.yaml
# for an example configuration).
#
# Example starting a mirror for the ghcr.io container registry:
#
# start-container-registry-mirror.sh \
#   --port 5001 \
#   --dir ~/.registry/ghcr.io \
#   --name registry-ghcr \
#   --proxy https://ghcr.io
#############################################################################

set -euo pipefail

REGISTRY_PORT=5000
REGISTRY_DIR=$HOME/.registry/docker.io
REGISTRY_NAME=registry-docker
REGISTRY_PROXY=https://index.docker.io
USERNAME=
PASSWORD=

function usage() {
    echo "Usage: $0 [OPTION]..."
    echo "Start a docker container providing a container registry mirror".
    echo
    echo "  --dir=DIRECTORY     use DIRECTORY on the host for storing registry config and data (default $REGISTRY_DIR)."
    echo "  -h, --help          display this help and exit"
    echo "  --port=PORT         use PORT as the registry's host port (default $REGISTRY_PORT)"
    echo "  --name=NAME         use NAME as the container's name (default $REGISTRY_NAME)"
    echo "  --proxy=URL         proxy requests to URL (default $REGISTRY_PROXY)"
    echo "  --username=USERNAME if set and --password is set, use USERNAME for authenticating with the proxied registry (default empty)"
    echo "  --password=PASSWORD if set and --username is set, use PASSWORD for authenticating with the proxied registry (default empty)"
}

if ! OPTS=$(getopt -o 'h' --long 'help,port:,dir:,name:,proxy:,username:,password:' -- "$@"); then
    usage
    exit 1
fi
eval set -- "$OPTS"
unset OPTS

while true ; do
    case "$1" in
        '-h'|'--help')
            usage
            exit 0
            ;;
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

if ! docker network inspect kind >/dev/null 2>&1 ; then
    docker network create --label registry-proxy kind
else
    networkLabel="$(docker network inspect kind|jq '.[0].Labels["registry-proxy"]')"
    if [ "$networkLabel" == "null" ] ; then
        echo "the kind network doesn't have the registry-proxy label which is needed to exclude it from pruning. Bailing out now."
        exit 1
    fi
fi

echo "Starting registry on port ${REGISTRY_PORT} ${REGISTRY_DIR}"

docker run -l registry-proxy --network kind -d --restart=always -p "${REGISTRY_PORT}":5000 --name "${REGISTRY_NAME}" -v "${REGISTRY_DIR}":/var/lib/registry registry:2 /var/lib/registry/config.yml
