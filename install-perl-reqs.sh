#!/bin/bash

# install perl reqs
for i in `cat requirements.txt`; do
	cpanm --self-contained "$i"
done
