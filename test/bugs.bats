#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/util'


output=$( load_fixture "chromium-modaltoelement" | $diff_so_fancy )


empty_remove_highlight="[m[1;31;48;5;52m[m[1;31m"

# https://github.com/paulirish/dotfiles/commit/6743b907ff586c28cd36e08d1e1c634e2968893e#commitcomment-13459061
@test "All removed lines are present in diff" {
  assert_output --partial "WebInspector.Dialog = function($empty_remove_highlight)"
  assert_output --partial "show: function($empty_remove_highlight)"
  assert_output --partial "{!Document} */ (WebInspector.Dialog._modalHostView.element.ownerDocument$empty_remove_highlight)"
}

@test "File with space in the name (#360)" {
	output=$( load_fixture "file_with_space" | $diff_so_fancy )
	run printf "%s" "$output"

	assert_line --index 1 --regexp "added:.*a b"
}

@test "Vanilla diff with add/remove empty lines (#366)" {
	output=$( load_fixture "add_remove_empty_lines" | $diff_so_fancy )
	run printf "%s" "$output"

	assert_line --index 5 --partial  "[7m[1;32"
	assert_line --index 8 --partial  "[7m[1;31"
}
