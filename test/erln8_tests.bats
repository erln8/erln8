#!/usr/bin/env bats

setup() {
  echo "Test setup"
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
    [ ! -e "./testconfig/.erln8.d/logs" ]
    [ ! -e "./testconfig/.erln8.d/otps" ]
   result="$($erln8_bin --buildable)"
}
