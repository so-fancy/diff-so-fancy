#!/usr/bin/env bats

load 'test_helper/bats-core/load'
load 'test_helper/bats-assert/load'
load 'test_helper/util'


# bats fails to handle our multiline result, so we save to $output ourselves
output=$( load_fixture "ls-function" | $diff_so_fancy )

@test "diff-so-fancy runs exits without error" {
  load_fixture "ls-function" | $diff_so_fancy
  assert_success
}

@test "original source is indented by a single space" {
  assert_output --partial "
 if begin[m"
}

@test "index line is removed entirely" {
  refute_output --partial "index 33c3d8b..fd54db2 100644"
}

@test "+/- line stars are stripped" {
  refute_output --partial "
[1;31m-"
  refute_output --partial "
[1;32m+"
}

@test "empty lines added/removed are marked" {
  assert_output --partial "[7m[1;32m [m
[1;32m [m[1;32m    set -x CLICOLOR_FORCE 1[m"
  assert_output --partial "[7m[1;31m [m
   if not set -q LS_COLORS[m"
}

@test "diff-highlight is highlighting changes within lines" {
  assert_output --partial 'eval [m[1;31;48;5;52m"env CLICOLOR_FORCE=1 command $ls $param [m[1;31m$argv"[m'
  assert_output --partial 'eval [m[1;32;48;5;22m$ls $param "[m[1;32m$argv"[m'
}

