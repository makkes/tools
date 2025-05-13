#!/usr/bin/env bash
#
# requires:
#
# - qrtool: https://sorairolake.github.io/qrtool/book/install.html


set -euo pipefail

echo -n "SSID: "
read -r SSID
echo -n "Passphrase: "
read -r PASS
echo -n "Hidden? [Y/n]: "
read -r HIDDEN

case "${HIDDEN,,}" in
    y | "")
        HIDDEN=true
        ;;
    n)
        HIDDEN=false
        ;;
    *)
        echo "unknown input '${HIDDEN}'"
        exit 1
        ;;
esac

qrtool encode 'WIFI:T:WPA;S:'"${SSID}"';P:'"${PASS}"';H:'"${HIDDEN}"';' > qrcode.png

echo "QR code written to qrcode.png"
