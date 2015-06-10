#!/usr/bin/env bats

setup() {
  d="/testconfig"
  export ERLN8_HOME=$PWD$d
  export ERLN8_OTP_DEFAULT_URL=https://github.com/erln8/fake_otp.git
  mkdir -p ./testconfig
}

teardown() {
  echo "Test teardown"
  rm -rf ./testconfig
}

erln8_bin="../erln8"

@test "Sanity check" {
  $erln8_bin --help
}

@test "erln8 initializes itself" {
    [ ! -e "./testconfig/.erln8.d/config" ]
    [ ! -e "./testconfig/.erln8.d/repos" ]
    [ ! -e "./testconfig/.erln8.d/otps" ]
   result="$($erln8_bin --buildable)"
    [ -e "./testconfig/.erln8.d/config" ]
    [ -e "./testconfig/.erln8.d/repos" ]
    [ -e "./testconfig/.erln8.d/otps" ]
}
