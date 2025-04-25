#!/bin/sh

(fehl --bg-fill --randomize $HOME/.de/feh/bg/*) &

(xsetroot -name "$(date '+%H:%M')") &

exec dwm
