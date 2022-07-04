#!/usr/bin/env bash

set -euo pipefail

case "${1:-}" in
    light)
        sed -i 's/^"\(set background=light\)$/\1/' ~/.vim/vimrc_local
        sed -i 's/^\(set background=dark\)$/"\1/' ~/.vim/vimrc_local
        sed -i 's/"workbench.colorTheme": "Solarized Dark",/"workbench.colorTheme": "Solarized Light",/' ~/.config/Code/User/settings.json
        ln -sf ~/.config/alacritty/themes/solarized_light.yaml ~/.config/alacritty/theme.yml && touch ~/.config/alacritty/alacritty.yml
        if [ "${2:-}" = "gtk" ] ; then
            sed -i 's/^gtk-application-prefer-dark-theme=1$/gtk-application-prefer-dark-theme=0/' ~/.config/gtk-{3,4}.0/settings.ini
        fi
        [ -r ~/.mutt/muttrc ] && sed -i 's/^source ~\/.mutt\/mutt-colors-solarized-dark-16\.muttrc$/source ~\/.mutt\/mutt-colors-solarized-light-16.muttrc/' ~/.mutt/muttrc
        [ -r ~/.config/glow/glow.yml ] && yq -i e '.style = "light"' ~/.config/glow/glow.yml
        ;;
    dark)
        sed -i 's/^"\(set background=dark\)$/\1/' ~/.vim/vimrc_local
        sed -i 's/^\(set background=light\)$/"\1/' ~/.vim/vimrc_local
        sed -i 's/"workbench.colorTheme": "Solarized Light",/"workbench.colorTheme": "Solarized Dark",/' ~/.config/Code/User/settings.json
        ln -sf ~/.config/alacritty/themes/solarized_dark.yaml ~/.config/alacritty/theme.yml && touch ~/.config/alacritty/alacritty.yml
        if [ "${2:-}" = "gtk" ] ; then
            sed -i 's/^gtk-application-prefer-dark-theme=0$/gtk-application-prefer-dark-theme=1/' ~/.config/gtk-{3,4}.0/settings.ini
        fi
        sed -i 's/^source ~\/.mutt\/mutt-colors-solarized-light-16\.muttrc$/source ~\/.mutt\/mutt-colors-solarized-dark-16.muttrc/' ~/.mutt/muttrc
        yq -i e '.style = "dark"' ~/.config/glow/glow.yml
        ;;
    ?)
esac
