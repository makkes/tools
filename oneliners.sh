#!/bin/bash

# This script is meant as a collection of one-liners that I use on a regular basis. Just symlink it using one of the following names for the symlink
# to get the approriate functionality:
#
# open-files-per-command: lists the number of open files per command that's currently running.
# wait-for-docker: continuously checks if Docker engine is up and running and exists as soon as it is, playing a notification sound.
# monitor-connectivity: continuously checks whether the machine has connectivity to the internet and if not plays a notification sound.
# git-prune-branches: deletes all local branches whose remote tracking branch has gone.

set -euo pipefail

CMD=$(basename ${0-})

case $CMD in
    open-files-per-command)
        IFS=$'\n'; for i in $(ps -A -o pid= -o command=|sed 's/^ *//') ; do printf '%10s %s\n' $(sudo lsof -p $(echo $i | cut -d" " -f1)|tail -n+2|wc -l) $(echo $i | cut -d" " -f2-) ; done
        ;;
    wait-for-docker)
        while ! docker ps ; do sleep 1 ; done && afplay ~/Desktop/cabin_chime.mp3
        ;;
    monitor-connectivity)
        while ! ping -c1 google.com ; do sleep 1 ; done && afplay ~/Desktop/cabin_chime.mp3
        ;;
    git-prune-branches)
        git fetch -tpP && git branch -vv|grep ': gone]'|grep -v '^\* '|awk '{print $1}'|xargs -r git branch -D
        ;;
    *)
        echo "Unknown command $CMD"
        exit 1
        ;;
esac
