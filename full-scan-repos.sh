#!/bin/bash

for D in ./gitrepos/*; do 
    [ -d "${D}" ] && echo "${D}" && docker run -it --rm --env-file=.env -v "$PWD/${D}":/gitrepo local-sonar-history-runner; 
done

