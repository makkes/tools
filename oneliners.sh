#!/bin/bash

# This script is meant as a collection of one-liners that I use on a regular basis. Just symlink it using one of the following names for the symlink
# to get the approriate functionality:
#
# open-files-per-command: lists the number of open files per command that's currently running.
# wait-for-docker: continuously checks if Docker engine is up and running and exists as soon as it is, playing a notification sound.
# monitor-connectivity: continuously checks whether the machine has connectivity to the internet and if not plays a notification sound.
# git-prune-branches: deletes all local branches whose remote tracking branch has gone.

set -euo pipefail

say=
if command -v say > /dev/null; then
    say=say
elif command -v espeak-ng > /dev/null ; then
    say=espeak-ng
fi

declare -A cmds
cmds[wait-for-docker]="while ! docker ps ; do sleep 1 ; done && ${say} 'docker is running'"
cmds[open-files-per-command]='IFS=$'"'\n'"'; for i in $(ps -A -o pid= -o command=|sed "s/^ *//") ; do printf "%10s %s\n" $(sudo lsof -p $(echo $i | cut -d" " -f1)|tail -n+2|wc -l) $(echo $i | cut -d" " -f2-) ; done'
cmds[monitor-connectivity]='while ! ping -c1 google.com ; do sleep 1 ; done && '${say}" 'connectivity established'"
cmds[git-prune-branches]='git fetch -tpPf ${1:-} && git branch --no-color -vv|grep ": gone]"|grep -v "^\* "|awk "{print \$1}"|xargs -r git branch -D'
cmds[kind-with-metallb]='kind create cluster && helm repo add bitnami https://charts.bitnami.com/bitnami && helm repo up && helm upgrade --install -n metallb --create-namespace --set configInline.address-pools[0].name=default --set configInline.address-pools[0].protocol=layer2 --set configInline.address-pools[0].addresses={"$(docker network inspect kind -f "{{(index .IPAM.Config 0).Subnet}}"|cut -d"." -f1-2).255.1-$(docker network inspect kind -f "{{(index .IPAM.Config 0).Subnet}}"|cut -d"." -f1-2).255.99"} metallb bitnami/metallb && ([ "${1:-}" != "--with-ingress-nginx" -a "${2:-}" != "--with-ingress-nginx" ] || (helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace))'
cmds[webp-to-gif]='python3 -c "from PIL import Image; import sys; im = Image.open(sys.argv[1]); im.save(sys.argv[2], '"'"'gif'"'"', save_all=True, optimize=True, background=0)" $1 $2'
cmds[docker-hub-proxy]='[ -z "${REGISTRY_PROXY_PASSWORD:-}" ] && echo "please set REGISTRY_PROXY_PASSWORD" || [ -z "${REGISTRY_PROXY_USERNAME:-}" ] && echo "please set REGISTRY_PROXY_USERNAME" || docker run -d --name proxy --restart=always --net=kind -p 5000:5000 -v $HOME/registry:/var/lib/registry -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io -e REGISTRY_PROXY_USERNAME=${REGISTRY_PROXY_USERNAME} -e REGISTRY_PROXY_PASSWORD=${REGISTRY_PROXY_PASSWORD} registry:2
'

function usage() {
    for cmd in "${!cmds[@]}" ; do
        echo "ln -fs $(readlink -f "${0}") ~/.local/bin/$cmd"
    done
    exit 1
}

CMD=$(basename "${0-}")
eval "${cmds[$CMD]:-usage}"
