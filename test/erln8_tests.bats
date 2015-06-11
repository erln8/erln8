#!/usr/bin/env bats

setup() {
  d="/testconfig"
  export ERLN8_HOME=$PWD$d
  export ERLN8_OTP_DEFAULT_URL=https://github.com/erln8/fake_otp.git
  mkdir -p ./testconfig
}

erln8_bin="../erln8"


teardown() {
  echo "Test teardown"
  rm -rf ./testconfig
}

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
    # sanity check that the config content exists
    [ `grep "color" ./testconfig/.erln8.d/config` = "color=true" ]
}


@test "erln8 remotes" {
  result="$($erln8_bin --remote add foobar123 https://github.com/erln8/fake_otp2.git)"
  [ `grep "foobar123" ./testconfig/.erln8.d/config | wc -l` = "1" ]

  result="$($erln8_bin --remote remove foobar123)"
  [ `grep "foobar123" ./testconfig/.erln8.d/config | wc -l` = "0" ]
}


@test "erln8 clone" {
  [ ! -e "./testconfig/.erln8.d/repos/foobar123" ]

  result="$($erln8_bin --remote add foobar123 https://github.com/erln8/fake_otp.git)"
  result="$($erln8_bin --clone foobar123)"
  [ -e "./testconfig/.erln8.d/repos/foobar123" ]
  [ -e "./testconfig/.erln8.d/repos/foobar123/.git" ]
}

@test "erln8 clone invalid" {
  [ ! -e "./testconfig/.erln8.d/repos/foobar123" ]

  run ../erln8 --clone foobar456
  [ "$status" -ne 0 ]
  [ ! -e "./testconfig/.erln8.d/repos/foobar456" ] 
}


@test "erln8 fetch" {
  result="$($erln8_bin --remote add foobar123 https://github.com/erln8/fake_otp.git)"
  result="$($erln8_bin --clone foobar123)"
  run $erln8_bin --fetch foobar123
  [ "$status" -eq 0 ]  
}


@test "erln8 fetch invalid repo" {
  # foobar456 does not exist
  run $erln8_bin --fetch foobar456
  [ "$status" -ne 0 ]  
}
