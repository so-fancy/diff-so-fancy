#!/usr/bin/env bats

# Used by both `setup_file` and `setup`, which are special bats callbacks.
__load_imports__() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'
	load 'test_helper/util'
}

setup_file() {
	__load_imports__
	setup_default_dsf_git_config
}

setup() {
	__load_imports__
}

teardown_file() {
	teardown_default_dsf_git_config
}

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

@test "recursive vanilla diff -r -bu as Mercurial (#436)" {
	output=$( load_fixture "recursive_default_as_mercurial" | $diff_so_fancy )
	run printf "%s" "$output"

	assert_line --index 1 --partial "renamed:"
	assert_line --index 3 --partial "@ language/app.py:1 @"
	assert_line --index 19 --partial "renamed:"
	assert_line --index 21 --partial "@ language/__init__.py:1 @"
	assert_line --index 25 --partial "renamed:"
	assert_line --index 27 --partial "@ language/README.md:1 @"
}

@test "recursive vanilla diff --recursive -u as Mercurial (#436)" {
	output=$( load_fixture "recursive_longhand_as_mercurial" | $diff_so_fancy )
	run printf "%s" "$output"

	assert_line --index 1 --partial "renamed:"
	assert_line --index 3 --partial "@ language/app.py:1 @"
	assert_line --index 19 --partial "renamed:"
	assert_line --index 21 --partial "@ language/__init__.py:1 @"
	assert_line --index 25 --partial "renamed:"
	assert_line --index 27 --partial "@ language/README.md:1 @"
}

@test "Functional part with bright color (#444)" {
  output=$( load_fixture "move_with_content_change" | $diff_so_fancy )
  run printf "%s" "$output"
  assert_line --index 3 --partial  "@[0m[93m height"
}
