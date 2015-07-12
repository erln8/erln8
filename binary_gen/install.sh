#!/bin/sh
mkdir -p ~/.erln8.d/bin
# NOTE: yes, this copies the erln8 binary *4* times
cp erln8 ~/.erln8.d/bin/erln8
cp erln8 ~/.erln8.d/bin/reo
cp erln8 ~/.erln8.d/bin/reo3
cp erln8 ~/.erln8.d/bin/extract

~/.erln8.d/bin/erln8 --clone default
~/.erln8.d/bin/reo --clone default
~/.erln8.d/bin/reo3 --clone default
~/.erln8.d/bin/extract --clone default
