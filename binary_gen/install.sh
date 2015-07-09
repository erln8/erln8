#!/bin/sh
mkdir -p ~/.erln8.d/bin
cp erln8 ~/.erln8.d/bin/erln8
cp erln8 ~/.erln8.d/bin/reo
cp erln8 ~/.erln8.d/bin/reo3
~/.erln8.d/bin/erln8 --clone default
~/.erln8.d/bin/reo --clone default
~/.erln8.d/bin/reo3 --clone default
