#! /usr/bin/env bash

set -eu

ffmpeg -i $1 -vf scale=886:1920,fps=30 $2
