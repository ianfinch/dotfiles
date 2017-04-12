#!/bin/sh

docker run -it --rm --name perl --hostname perl -v "$PWD":/usr/src/perl -w /usr/src/perl perl:5.20 perl $*
