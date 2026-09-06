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

@test "In 'git show' mode with ISO date we add a human time (#540)" {
	output=$( load_fixture "gitshow-iso" | $diff_so_fancy | $ansi_reveal)
	run printf "%s" "$output"

	assert_line --index 4 --regexp "ago"
}

@test "Context lines starting with dash are not colored as removal (#542)" {
	output=$( load_fixture "markdown-list" | $diff_so_fancy | $ansi_reveal )
	run printf "%s" "$output"

	# Context lines with dash content should have NO color
	assert_line --index 5 --regexp '^- milk$'
	assert_line --index 8 --regexp '^- butter$'

	# Removal line should be RED
	assert_line --index 6 --regexp '^\[BOLD\]\[RED\].*eggs'

	# Addition line should be GREEN
	assert_line --index 7 --regexp '^\[BOLD\]\[GREEN\].*bread'
}

@test "Patch mode line count matches on add/delete" {
	for fixture in add_file_with_content delete_file_with_content; do
		local in out
		in=$( load_fixture "$fixture" | wc -l )
		out=$( load_fixture "$fixture" | $diff_so_fancy --patch | wc -l )
		[ "$in" -eq "$out" ] || fail "fixture '$fixture': $in input lines but $out output lines"
	done

	for fixture in add_empty_file remove_empty_file; do
		local bare in out
		bare=$( load_fixture "$fixture" | sed -n '/^diff --git/,$p' )
		in=$( printf '%s\n' "$bare" | wc -l )
		out=$( printf '%s\n' "$bare" | $diff_so_fancy --patch | wc -l )
		[ "$in" -eq "$out" ] || fail "fixture '$fixture' (bare): $in input lines but $out output lines"
	done
}

@test "File with a 'b/' prefix inside the name (#549)" {
	output=$( load_fixture "file-with-b-prefix-in-name" | $diff_so_fancy | $ansi_reveal )
	run printf "%s" "$output"

	assert_line --index 0 --partial "my b/file.txt changed file mode from 100644 to 100755"
	assert_line --index 4 --partial "@ my b/old.txt:1 @"
}

@test "Binary file with ' and ' in the name (#547)" {
	output=$( load_fixture "binary-modified-name-with-and" | $diff_so_fancy )
	run printf "%s" "$output"
	assert_line --index 1 --partial "modified: a and b.png (binary)";
}

# A diff that ends right after 'old mode' made dsf warn about an
# uninitialized value and abort (`use warnings FATAL => 'all'`).
@test "Truncated diff ending on an 'old mode' line (#550)" {
	run bash -c "cat '${BATS_TEST_DIRNAME}/fixtures/truncated-old-mode.diff' | $diff_so_fancy 2>&1"

	assert_success
	refute_output --partial "uninitialized value"
	assert_line --index 0 --partial "old mode 100644"
}

# A diff that ends right after 'similarity index' had its remaining lines
# swallowed: the branch consumed the two lines it expects to follow without
# checking they are there, so the whole diff vanished from the output.
@test "Truncated diff ending on a 'similarity index' line" {
	run bash -c "cat '${BATS_TEST_DIRNAME}/fixtures/truncated-similarity-index.diff' | $diff_so_fancy 2>&1"

	assert_success
	assert_line --index 0 --partial "similarity index 100%"

	run bash -c "cat '${BATS_TEST_DIRNAME}/fixtures/truncated-similarity-index-partial.diff' | $diff_so_fancy 2>&1"

	assert_success
	assert_line --index 0 --partial "similarity index 85%"
}
