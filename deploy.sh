#!/bin/sh
if [[ $(uname -v) == *"Ubuntu"* ]]; then
	sh ./aptdeploy.sh
else
	sh ./pacmandeploy.sh
fi
