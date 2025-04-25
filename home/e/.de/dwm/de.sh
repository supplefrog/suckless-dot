#!/bin/sh

(while true; do feh --bg-fill --randomize $HOME/.de/feh/bg/*; sleep 30; done) &

(while true; do xsetroot -name "$(date '+%H:%M')"; sleep 60; done) &

exec dwm
