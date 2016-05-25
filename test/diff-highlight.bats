#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/util'


# bats fails to handle our multiline result, so we save to $output ourselves
output=$( load_fixture "ls-function" | $diff_so_fancy )


setup() {
  users_path=$PATH
  mv "$BATS_TEST_DIRNAME/../third_party/diff-highlight/diff-highlight" "$BATS_TEST_DIRNAME"
  export PATH=$BATS_TEST_DIRNAME:$PATH
}

@test "diff-highlight resolved when already on path" {
  assert_output --partial 'eval [m[1;31;48;5;52m"env CLICOLOR_FORCE=1 command $ls $param [m[1;31m$argv"[m'
  assert_output --partial 'eval [m[1;32;48;5;22m$ls $param "[m[1;32m$argv"[m'
}

teardown() {
  export PATH=$users_path
  mv "$BATS_TEST_DIRNAME/diff-highlight" "$BATS_TEST_DIRNAME/../third_party/diff-highlight"
}
