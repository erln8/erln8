#!/bin/sh
cd .. && make && cd ./binary_gen
cd ./centos6 && ./build.sh && cd ..
cd ./centos7 && ./build.sh && cd ..
cd ./ubuntu1404 && ./build.sh && cd ..
cd ./ubuntu1504 && ./build.sh && cd ..
python upload.py
