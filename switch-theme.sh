#!/usr/bin/env bash

set +e

case "${1:-}" in
    light)
        if [ -f ~/.tmux.conf ] ; then
            sed -i 's/^#\(.* # theme:light\)$/\1/' ~/.tmux.conf
            sed -i 's/^\([^#].* # theme:dark\)$/#\1/' ~/.tmux.conf
        fi
        if [ -d ~/.config/i3 ] ; then
            sed -i 's/^#\(.* # theme:light\)$/\1/' ~/.config/i3/config
            sed -i 's/^\([^#].* # theme:dark\)$/#\1/' ~/.config/i3/config
            i3-msg restart
        fi
        [ -d ~/.config/kitty ] && ln -sf ~/.config/kitty/themes/Solarized_Light.conf ~/.config/kitty/theme.conf && for pid in $(pidof kitty) ; do kill -USR1 "${pid}" ; done
        sed -i 's/^skin=.*$/skin=solarized-light-truecolor/' ~/.config/mc/ini
        sed -i 's/^"\(set background=light\)$/\1/' ~/.vim/vimrc_local
        sed -i 's/^\(set background=dark\)$/"\1/' ~/.vim/vimrc_local
        sed -i 's/"workbench.colorTheme": "Solarized Dark",/"workbench.colorTheme": "Solarized Light",/' ~/.config/Code/User/settings.json
        [ -d ~/.config/alacritty ] && ln -sf ~/.config/alacritty/themes/solarized_light.yaml ~/.config/alacritty/theme.yml && touch ~/.config/alacritty/alacritty.yml
        if [ "${2:-}" = "gtk" ] ; then
            sed -i 's/^gtk-application-prefer-dark-theme=1$/gtk-application-prefer-dark-theme=0/' ~/.config/gtk-{3,4}.0/settings.ini
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
        fi
        [ -r ~/.mutt/muttrc ] && sed -i 's/^source ~\/.mutt\/mutt-colors-solarized-dark-16\.muttrc$/source ~\/.mutt\/mutt-colors-solarized-light-16.muttrc/' ~/.mutt/muttrc
        [ -r ~/.config/glow/glow.yml ] && yq -i e '.style = "light"' ~/.config/glow/glow.yml
        exit 0
        ;;
    dark)
        if [ -f ~/.tmux.conf ] ; then
            sed -i 's/^#\(.* # theme:dark\)$/\1/' ~/.tmux.conf
            sed -i 's/^\([^#].* # theme:light\)$/#\1/' ~/.tmux.conf
        fi
        if [ -d ~/.config/i3 ] ; then
            sed -i 's/^#\(.* # theme:dark\)$/\1/' ~/.config/i3/config
            sed -i 's/^\([^#].* # theme:light\)$/#\1/' ~/.config/i3/config
            i3-msg restart
        fi
        [ -d ~/.config/kitty ] && ln -sf ~/.config/kitty/themes/Solarized_Dark_-_Patched.conf ~/.config/kitty/theme.conf && for pid in $(pidof kitty) ; do kill -USR1 "${pid}" ; done
        sed -i 's/^skin=.*$/skin=solarized-dark-truecolor/' ~/.config/mc/ini
        sed -i 's/^"\(set background=dark\)$/\1/' ~/.vim/vimrc_local
        sed -i 's/^\(set background=light\)$/"\1/' ~/.vim/vimrc_local
        sed -i 's/"workbench.colorTheme": "Solarized Light",/"workbench.colorTheme": "Solarized Dark",/' ~/.config/Code/User/settings.json
        [ -d ~/.config/alacritty ] && ln -sf ~/.config/alacritty/themes/solarized_dark.yaml ~/.config/alacritty/theme.yml && touch ~/.config/alacritty/alacritty.yml
        if [ "${2:-}" = "gtk" ] ; then
            sed -i 's/^gtk-application-prefer-dark-theme=0$/gtk-application-prefer-dark-theme=1/' ~/.config/gtk-{3,4}.0/settings.ini
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        fi
        sed -i 's/^source ~\/.mutt\/mutt-colors-solarized-light-16\.muttrc$/source ~\/.mutt\/mutt-colors-solarized-dark-16.muttrc/' ~/.mutt/muttrc
        [ -r ~/.config/glow/glow.yml ] && yq -i e '.style = "dark"' ~/.config/glow/glow.yml
        exit 0
        ;;
    ?)
esac
