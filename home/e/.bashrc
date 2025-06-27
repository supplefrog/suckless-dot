# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

#if [ -z "$OPEN" ]; then
#    export OPEN=1
#    st &
#    python3.13 $HOME/.de/anifetch/anifetch.py -f $HOME/.de/anifetch/example.mp4
#    printf '\n\n'
#fi

TIME=$(date '+%H:%M')
echo -e "\e[31m${TIME:0:1}\e[33m${TIME:1:1}\e[32m${TIME:2:1}\e[36m${TIME:3:1}\e[34m${TIME:4:1}\e[0m"
