#! /usr/bin/env bash

set -eu

ffmpeg -f lavfi -i anullsrc -c:a aac -i $1 -vf scale=886:1920,fps=30 -map 0:a -map 1:v -shortest $2
