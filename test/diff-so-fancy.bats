#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/util'

set_env

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

@test "+/- line symbols are stripped" {
  refute_output --partial "
[1;31m-"
  refute_output --partial "
[1;32m+"
}

@test "empty lines added/removed are marked" {
  assert_output --partial "[7m[1;32m [m
[1;32m[m[1;32m    set -x CLICOLOR_FORCE 1[m"
  assert_output --partial "[7m[1;31m [m
  if not set -q LS_COLORS[m"
}

@test "diff --git line is removed entirely" {
  # test against ls-function
  refute_output --partial "diff --git a/fish/functions/ls.fish"
  # test with git config diff.noprefix true
  output=$( load_fixture "noprefix" | $diff_so_fancy )
  refute_output --partial "diff --git setup-a-new-machine.sh"
}

@test "header format uses a native line-drawing character" {
  header=$( printf "%s" "$output" | head -n3 )
  run printf "%s" "$header"
  assert_line --index 0 --partial "[1;33m─────"
  assert_line --index 1 --partial "modified: fish/functions/ls.fish"
  assert_line --index 2 --partial "[1;33m─────"
}

# see https://git.io/vrOF4
@test "Should not show unicode bytes in hex if missing LC_*/LANG _and_ piping the output" {
  unset LESSCHARSET LESSCHARDEF LC_ALL LC_CTYPE LANG
  # pipe to cat(1) so we don't open stdout
  header=$( printf "%s" "$(load_fixture "ls-function" | $diff_so_fancy | cat)" | head -n3 )
  run printf "%s" "$header"
  assert_line --index 0 --partial "[1;33m-----"
  assert_line --index 1 --partial "modified: fish/functions/ls.fish"
  assert_line --index 2 --partial "[1;33m-----"
  set_env # reset env
}

@test "Leading dashes are not handled as modified" {
  output=$( load_fixture "leading-dashes" | $diff_so_fancy )
  refute_output --partial "modified: Callback"
}

@test "Handle binary modifications" {
  output=$( load_fixture "binary-modified" | $diff_so_fancy )
  run printf "%s" "$output"
  assert_line --index 1 --partial "modified: cancel.png (binary)";
}

@test "Handle unicode characters in diff output" {
  output=$( load_fixture "unicode" | $diff_so_fancy )
  run printf "%s" "$output"
  assert_line --index 5 --partial "åäöç"
}

@test "Handle latin1 encoding sanely" {
  output=$( load_fixture "latin1" | $diff_so_fancy )
  # Make sure the output contains SOME of the english text (i.e. it doesn't barf on the whole line)
  assert_output --partial "saw he conqu"
}

@test "Correctly handle hunk definition with no comma" {
  output=$( load_fixture "hunk_no_comma" | $diff_so_fancy )
  # On single line removes there is NO comma in the hunk,
  # make sure the first column is still correctly stripped.
  run printf "%s" "$output"
  assert_line --index 5 "after"
}
