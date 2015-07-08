#!/bin/sh
mkdir -p repos
if [ ! -d ./repos/default_otp ]
then
  git clone /Users/dparfitt/src/erlang_repos/otp ./repos/default_otp
fi

if [ ! -d ./repos/basho_otp ]
then
  git clone /Users/dparfitt/src/erlang_repos/basho_otp ./repos/basho_otp
fi
./erln8_tests.bats
