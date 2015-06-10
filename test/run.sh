#!/bin/sh
git clone https://github.com/erln8/fake_otp.git repoA
git clone https://github.com/erln8/fake_otp.git repoB
git clone https://github.com/erln8/fake_otp.git repoC
./erln8_tests.bats
