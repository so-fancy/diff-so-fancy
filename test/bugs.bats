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
	output=$( load_fixture "chromium-modaltoelement" | $diff_so_fancy | $ansi_reveal)
	run printf "%s" "$output"

	assert_line --index 7 --partial "[BOLD][RED]WebInspector.Dialog"
	assert_line --index 8 --partial "[BOLD][GREEN]WebInspector.Dialog"
}

@test "File with space in the name (#360)" {
	output=$( load_fixture "file_with_space" | $diff_so_fancy )
	run printf "%s" "$output"

	assert_line --index 1 --regexp "added:.*a b"
}

@test "Vanilla diff with add/remove empty lines (#366)" {
	output=$( load_fixture "add_remove_empty_lines" | $diff_so_fancy | $ansi_reveal )
	run printf "%s" "$output"

	assert_line --index 5 --partial "[REVERSE][BOLD][GREEN][BACKG022] [RESET]" # green added line
	assert_line --index 8 --partial "[REVERSE][BOLD][RED][BACKG052] [RESET]" # red removed line
}

@test "recursive vanilla diff -r -bu as Mercurial (#436)" {
	output=$( load_fixture "recursive_default_as_mercurial" | $diff_so_fancy | $ansi_reveal )
	run printf "%s" "$output"

	assert_line --index 1 --partial "modified:"
	assert_line --index 3 --partial "@ language/app.py:1 @"
	assert_line --index 19 --partial "modified:"
	assert_line --index 21 --partial "@ language/__init__.py:1 @"
	assert_line --index 25 --partial "modified:"
	assert_line --index 27 --partial "@ language/README.md:1 @"
}

@test "recursive vanilla diff --recursive -u as Mercurial (#436)" {
	output=$( load_fixture "recursive_longhand_as_mercurial" | $diff_so_fancy )
	run printf "%s" "$output"

	assert_output --regexp 'modified: app.py'
	assert_output --regexp 'modified: __init__.py'
	assert_output --regexp 'modified: README.md'
}

@test "Functional part with bright color (#444)" {
	output=$( load_fixture "move_with_content_change" | $diff_so_fancy | $ansi_reveal )
	run printf "%s" "$output"
	assert_line --index 3 --partial  "[BRT-YELLW] height:"
	assert_line --index 8 --partial  "[BOLD][GREEN]bottom: '0'"
	assert_line --index 7 --partial  "[BOLD][RED]bottom: '0'"
}

@test "ANSI Reset without the zero (#469)" {
	output=$( load_fixture "ansi_reset_no_number" | $diff_so_fancy )
	run printf "%s" "$output"
	assert_line --index 5 --partial  "History"
}

@test "File copy detection (#349)" {
	output=$( load_fixture "file_copy" | $diff_so_fancy )
	run printf "%s" "$output"
	assert_output --regexp 'Copied first_file to copied_file'
}

@test "diff --recursive support (#394)" {
	output=$( load_fixture "diff_recursive" | $diff_so_fancy )
	run printf "%s" "$output"
	assert_output --regexp 'modified: foo/bar'
	assert_output --regexp 'modified: index.txt'
}

@test "Remove a \n at the end of a file (#474)" {
	output=$( load_fixture "remove_slashn_eof" | $diff_so_fancy | $ansi_reveal)
	run printf "%s" "$output"
	assert_line --index 6 --partial "[BOLD][RED]three[RESET]"
	assert_line --index 7 --partial "[BOLD][GREEN]three[RESET]"
}

@test "Single line input passes through d-s-f (#511)" {
	output=$( load_fixture "oneline" | $diff_so_fancy )
	run printf "%s" "$output"
	assert_line --index 0 --regexp "one line"
}

@test "In 'git show' mode we highlight the commit (#398)" {
	output=$( load_fixture "gitshow" | $diff_so_fancy | $ansi_reveal)
	run printf "%s" "$output"

	assert_line --index 1 --regexp "commit 943ef89c4"
	assert_line --index 6 --regexp "^\[COLOR227\]──────────────────────────┐"
	assert_line --index 8 --regexp "^\[COLOR227\]──────────────────────────┘"
}
