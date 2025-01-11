#!/bin/sh

FROM_DIR=.
TO_DIR=we@norns.lan:/home/we/dust/code/clockabout
rsync --recursive --delete --itemize-changes \
    --exclude=.git \
    --exclude='*.swp' \
    --exclude=push.sh \
    "$FROM_DIR" "$TO_DIR"
