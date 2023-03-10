#!/usr/bin/env bash

# You can call this script like this:
# $ ./brightnessControl.sh up
# $ ./brightnessControl.sh down

# Script inspired by these wonderful people:
# https://github.com/dastorm/volume-notification-dunst/blob/master/volume.sh
# https://gist.github.com/sebastiencs/5d7227f388d93374cebdf72e783fbd6a

set -euo pipefail

function get_brightness {
    xbacklight -get
}

function send_notification {
    icon="display-brightness-symbolic"
    msg="Brightness: $(get_brightness | xargs printf '%.f')%"
    dunstify -t 1000 -i "$icon" -r 5555 -u normal -h "int:value:$(get_brightness)" "${msg}"
}

case ${1:-} in
    up)
        # increase the backlight by 5%
        xbacklight -inc "${2:-5}"
        send_notification
        ;;
    down)
        # decrease the backlight by 5%
        xbacklight -dec "${2:-5}"
        send_notification
        ;;
    *)
        echo "usage: $(basename "$0") up|down"
esac
