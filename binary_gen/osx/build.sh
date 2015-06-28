#!/bin/sh
mkdir -p ./erln8
cp ../../LICENSE ./erln8
cp ../install.sh ./erln8
cp ../../erln8 ./erln8/erln8
cp ../../erln8 ./erln8/reo
cp ../../erln8 ./erln8/reo3
tar cvzf ./erln8_osx.tgz ./erln8/*
