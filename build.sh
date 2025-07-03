#!/bin/bash

set -e

SRC=nrpe-data-exporter.pl

# this script should be run inside a Rocky9 container, e.g.:
# docker run --rm -it -v "$PWD":/src --name rocky9builder rockylinux:9 bash -c "cd /src; ./build.sh"

# install build reqs
dnf install -y gcc make perl perl-App-cpanminus

# install Perl dependencies
./install-perl-reqs.sh

# compile as a standalone executable, go style
pp -x --xargs=-h -o "$(basename "$SRC" .pl )" "$SRC"
