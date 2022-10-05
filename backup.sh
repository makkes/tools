#!/usr/bin/env bash

set -euo pipefail

BKPDIR=/media/max/makkes/$(hostname)
if [[ -z $(findmnt --target "$BKPDIR") ]] ; then
    echo "Backup drive not mounted, ${BKPDIR} not found; exiting"
    exit
fi

BASEDIR=$(dirname "${BASH_SOURCE[0]}")
LOGDIR="$HOME/backups/"
[ -d "$LOGDIR" ] || mkdir -p "$LOGDIR"

DATESTR=$(date +"%Y-%m-%d_%H:%M:%S")
LOGFILE=$LOGDIR/bkp-$DATESTR.log
ERRORLOGFILE=$LOGDIR/bkp-$DATESTR-error.log

rsync --exclude-from="$BASEDIR/backup.excl" -vaxAX --delete --ignore-errors / "$BKPDIR" > >(tee "$LOGFILE") 2> >(tee "$ERRORLOGFILE" >&2)
