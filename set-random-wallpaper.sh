#!/usr/bin/env bash

set -euo pipefail

DEFAULT_SRC_DIR=~/Pictures/Wallpapers
SRC_DIR=${1:-${DEFAULT_SRC_DIR}}
TGT_DIR=${2:-${SRC_DIR}}

function usage() {
    echo "Usage: $0 [SOURCE_DIRECTORY [TARGET_DIRECTORY]]"
    echo "Pick a random file as wallpaper and apply it"
    echo
    echo "This program picks a random file from SOURCE_DIRECTORY (non-recursively)"
    echo "and places the symlink named \"default\" into TARGET_DIRECTORY."
    echo
    echo "If TARGET_DIRECTORY is not provided then SOURCE_DIRECTORY directory is"
    echo "used as target directory."
    echo "If SOURCE_DIRECTORY is not provided then ${DEFAULT_SRC_DIR} is used."
    echo
    echo "This script comes with certain assumptions:"
    echo
    echo "1. nitrogen is installed: https://archlinux.org/packages/extra/x86_64/nitrogen/"
    echo "2. nitrogen is configured to use TARGET_DIRECTORY/default as wallpaper file"
}

if ! OPTS=$(getopt -o 'h' -- "$@"); then
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
        *)
            echo 'Internal error!' >&2
            exit 1
            ;;
    esac
done

ln -sf "${SRC_DIR}/$(find "${SRC_DIR}" -maxdepth 1 -type f -printf '%f\n' | sort -R | head -1)" "${TGT_DIR}"/default
nitrogen --restore
