#!/bin/zsh
/usr/local/bin/brew update >/dev/null && /usr/local/bin/brew upgrade >/dev/null
/usr/local/bin/brew list > ~/.brew_list
