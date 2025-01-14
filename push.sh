#!/bin/sh

FROM_DIR=.
TO_DIR=we@norns.lan:/home/we/dust/code/clockabout
rsync --recursive --delete --itemize-changes \
    --exclude=.git \
    --exclude=push.sh \
    --exclude-from=.gitignore \
    "$FROM_DIR" "$TO_DIR"
