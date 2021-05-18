#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/util'

# https://github.com/paulirish/dotfiles/commit/6743b907ff586c28cd36e08d1e1c634e2968893e#commitcomment-13459061
@test "All removed lines are present in diff" {
  output=$( load_fixture "chromium-modaltoelement" | $diff_so_fancy )
	run printf "%s" "$output"

  assert_line --index 7 --partial "WebInspector.Dialog"
  assert_line --index 7 --partial "5;52m" # red oldhighlight
  assert_line --index 8 --partial "WebInspector.Dialog"
  assert_line --index 8 --partial "5;22m" # green newhighlight
}

@test "File with space in the name (#360)" {
	output=$( load_fixture "file_with_space" | $diff_so_fancy )
	run printf "%s" "$output"

	assert_line --index 1 --regexp "added:.*a b"
}

@test "Vanilla diff with add/remove empty lines (#366)" {
	output=$( load_fixture "add_remove_empty_lines" | $diff_so_fancy )
	run printf "%s" "$output"

	assert_line --index 5 --partial  "5;22m" # green added line
	assert_line --index 8 --partial  "5;52m" # red removed line
}
