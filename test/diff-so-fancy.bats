#!/usr/bin/env bats

load 'test_helper/bats-support/load'
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

# github.com/paulirish/dotfiles/commit/6743b907ff586c28cd36e08d1e1c634e2968893e#commitcomment-13459061
@test "All removed lines are definitely printed" {
  output=$( load_fixture "chromium-modaltoelement" | $diff_so_fancy )
  lines=$( printf "%s" "$output")
  run printf "%s" "$lines"
  assert_line --partial --index 7 "WebInspector.Dialog = "
  assert_line --partial --index 8 "WebInspector.Dialog = "
  assert_line --partial --index 26 "show: function"
  assert_line --partial --index 27 "show: function"
  assert_line --partial --index 33 "Dialog._modalHostView.element.ownerDocument"
}
