#!/usr/bin/env bash

## Rofi Launcher Script

dir="$(dirname "$(readlink -f "$0")")"
theme='theme'

## Run
rofi \
    -show drun \
    -theme "${dir}/${theme}.rasi"
