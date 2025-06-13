#!/bin/sh

while true
    do feh --bg-fill --randomize $HOME/.de/feh/bg/*
    sleep 30
done &
exec sxwm
