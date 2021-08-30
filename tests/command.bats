#!/usr/bin/env bats

load "$BATS_PATH/load.bash"
load "$PWD/hooks/lib/cloudrc"

@test "parse array" {
  export ARRAY_VALUES_0=a
  export ARRAY_VALUES_1=b
  export ARRAY_VALUES_2=c

  IFS=" " read -r -a values < <(buildkite::readArray ARRAY_VALUES_[0-9]+)

  assert_equal "${values[0]}" "a"
  assert_equal "${values[1]}" "b"
  assert_equal "${values[2]}" "c"
}

