#!/usr/bin/env bash

set -euo pipefail


function usage() {
    echo "Usage: $0 [OPTION]..."
    echo "Prune asdf storage to free up disk space".
    echo
    echo "  -h, --help          display this help and exit"
    echo "  -d, --dry-run       don't free up any space but print what would be done"
}


if ! OPTS=$(getopt -o 'hd' --long 'help,dry-run' -- "$@"); then
    usage
    exit 1
fi
eval set -- "$OPTS"
unset OPTS

DRY_RUN=

while true ; do
    case "$1" in
        '-h'|'--help')
            usage
            exit 0
            ;;
        '-d'|'--dry-run')
            DRY_RUN=1
            shift
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

if [ -n "$DRY_RUN" ] ; then
    echo dry run...
fi

function prune() {
    local PKG="$1"
    local VERSION="${2##  }"
    
    echo -n "pruning $PKG $VERSION"
    if [ -n "$DRY_RUN" ] ; then
        echo " (dry-run)"
    else
        echo
        asdf uninstall "$PKG" "$VERSION"
    fi
}

PKG=
VERSION=
SIZE_BEFORE=$(du -s ~/.asdf|cut -f1)
while IFS= read -r line ; do
    if [[ "$line" =~ ^[[:space:]][[:space:]\*] ]] ; then
        if [ -n "$VERSION" ] ; then
            prune "$PKG" "$VERSION"
        fi
        VERSION="${line## \*}"
    else
        PKG="$line"
        VERSION=
    fi
done < <(asdf list 2>/dev/null)

SIZE_AFTER=$(du -s ~/.asdf|cut -f1)
echo "Saved $(echo "(${SIZE_BEFORE}-${SIZE_AFTER})/1024/1024" | bc) GiB"
