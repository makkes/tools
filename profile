#!/usr/bin/env bash

set -euo pipefail

function log() {
    echo "$@"
}

function usage() {
    log "Usage: $0 switch|stationary|mobile"
    log ""
    log "Switch machine between stationary or mobile mode."
    log ""
    log "Stationary mode turns Wifi off, Bluetooth on and configures"
    log "an external monitor."
    log ""
    log "Mobile mode does the opposite."
}

if [ -z "${1:-}" ] ; then
    usage
    exit 1
fi

MON=$(xrandr -q | grep ' connected ' | cut -d" " -f1 | grep -v '^eDP-1$' | tail -n1 || true)

function fix-workspace-positions() {
    set +e
    for i in 1 2 3 4 5 ; do
        i3-msg [workspace="^${i}"] move workspace to output primary
    done
    for i in 6 ; do
        i3-msg [workspace="^${i}"] move workspace to output nonprimary
    done
    set -e
}

function stationary() {
    log "configuring stationary mode with monitor $MON"
    xrandr --output eDP-1 --auto --output "$MON" --auto --right-of eDP-1 --primary
    fix-workspace-positions
    rfkill block wifi
    rfkill unblock bluetooth
}

function mobile() {
    log "configuring mobile mode"
    xrandr --listmonitors | tail -n+2 | cut -d" " -f6 | (grep -v '^eDP-1$' || true) | xargs -I{} xrandr --output {} --off
    xrandr --output eDP-1 --primary
    rfkill unblock wifi
    rfkill block bluetooth
}

case "${1}" in
    switch)
        if [ -z "$MON" ] ; then
            mobile
        else
            stationary "$MON"
        fi
        ;;
    stationary)
        stationary "$MON"
        ;;
    mobile)
        mobile
       ;;
    *)
        usage
        exit 1
esac
