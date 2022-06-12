#!/bin/bash

TMPFSMOUNT=""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Platform provide TMPFS mount https://docs.docker.com/storage/tmpfs/#limitations-of-tmpfs-mounts"
    TMPFSMOUNT="--tmpfs /tmp"
fi;

for D in ./gitrepos/*; do 
    [ -d "${D}" ] && echo "${D}" && docker run -it $TMPFSMOUNT --rm --env-file=.env -v "$PWD/${D}":/gitrepo local-sonar-history-runner; 
done
