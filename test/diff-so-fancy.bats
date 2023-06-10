#!/usr/bin/env bats

# Helper invoked by `setup_file` and `setup`, which are special bats callbacks.
__load_imports__() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'
	load 'test_helper/util'
}

setup_file() {
	__load_imports__
	set_env
	setup_default_dsf_git_config
	# bats fails to handle our multiline result, so we save to $output ourselves
	__dsf_cached_output="$( load_fixture "ls-function" | $diff_so_fancy )"
	export __dsf_cached_output
}

setup() {
	__load_imports__
	output="${__dsf_cached_output}"
}

teardown_file() {
	teardown_default_dsf_git_config
}

@test "diff-so-fancy runs and exits without error" {
	load_fixture "ls-function" | $diff_so_fancy
	run assert_success
}

@test "index line is removed entirely" {
	refute_output --partial "index 33c3d8b..fd54db2 100644"
}

@test "+/- line symbols are stripped" {
	run printf "%s" "$output"
	refute_line --index 9 --regexp "\+    set -x CLICOLOR_FORCE 1"
	refute_line --index 22 --regexp "-    eval \"env CLICOLOR"
}

@test "+/- line symbols are stripped (truecolor)" {
  output=$( load_fixture "truecolor" | $diff_so_fancy )
  refute_output --partial "
[1;38;2;220;50;47;48;2;0;43;54m-"
  refute_output --partial "
[1;38;2;133;153;0;48;2;0;43;54m+"
}

@test "empty lines added/removed are marked" {
	run printf "%s" "$output"

	assert_line --index 7 --partial  "[7m[1;32m [m"
	assert_line --index 24 --partial "[7m[1;31m [m"

	#assert_output --partial "[7m[1;32m [m"
	#assert_output --partial "[7m[1;31m [m"
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
  assert_line --index 0 --partial "─────"
  assert_line --index 1 --partial "modified: fish/functions/ls.fish"
  assert_line --index 2 --partial "─────"
}

# see https://git.io/vrOF4
@test "Should not show unicode bytes in hex if missing LC_*/LANG _and_ piping the output" {
  unset LESSCHARSET LESSCHARDEF LC_ALL LC_CTYPE LANG
  # pipe to cat(1) so we don't open stdout
  header=$( load_fixture "ls-function" | $diff_so_fancy | cat | head -n3 )
  run printf "%s" "$header"
  assert_line --index 0 --partial "-----"
  assert_line --index 1 --partial "modified: fish/functions/ls.fish"
  assert_line --index 2 --partial "-----"
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
  run printf "%s" "$output"
  assert_line --index 6 --partial "saw he conqu"
}

@test "Correctly handle hunk definition with no comma" {
  output=$( load_fixture "hunk_no_comma" | $diff_so_fancy )
  # On single line removes there is NO comma in the hunk,
  # make sure the first column is still correctly stripped.
  run printf "%s" "$output"
  assert_line --index 5 --regexp "after"
}

@test "Empty file add" {
  output=$( load_fixture "add_empty_file" | $diff_so_fancy )
  run printf "%s" "$output"
  assert_line --index 7 --regexp "added:.*empty_file.txt"
}

@test "Empty file delete" {
  output=$( load_fixture "remove_empty_file" | $diff_so_fancy )
  run printf "%s" "$output"
  assert_line --index 7 --regexp "deleted:.*empty_file.txt"
}

@test "Move with content change" {
  output=$( load_fixture "move_with_content_change" | $diff_so_fancy )
  run printf "%s" "$output"
  assert_line --index 1 --regexp "renamed:"
}

@test "Mercurial support" {
  output=$( load_fixture "hg" | $diff_so_fancy )
  run printf "%s" "$output"
  assert_line --index 1 --regexp "modified: hello.c"
}

@test "Handle file renames" {
	output=$( load_fixture "file-rename" | $diff_so_fancy )
	run printf "%s" "$output"
	assert_line --index 1 --partial "renamed:"
	assert_line --index 1 --partial "Changes.new"
	assert_line --index 1 --partial "bin/"
}

@test "header_clean 'added:'" {
	output=$( load_fixture "file-moves" | $diff_so_fancy )
	assert_output --regexp 'added:.*hello.txt'
}

@test "header_clean 'modified:'" {
	output=$( load_fixture "file-moves" | $diff_so_fancy )
	assert_output --partial 'modified: appveyor.yml'
}

@test "header_clean 'deleted:'" {
	output=$( load_fixture "file-moves" | $diff_so_fancy )
	assert_output --regexp 'deleted:.*circle.yml'
}

@test "header_clean permission changes" {
	output=$( load_fixture "file-perms" | $diff_so_fancy )
	assert_output --partial 'circle.yml changed file mode from 100644 to 100755'
}

@test "header_clean 'new file mode' is removed" {
	output=$( load_fixture "file-perms" | $diff_so_fancy )
	refute_output --partial 'new file mode'
}

@test "header_clean 'deleted file mode' is removed" {
	output=$( load_fixture "file-perms" | $diff_so_fancy )
	refute_output --partial 'deleted file mode'
}

@test "header_clean remove 'git --diff' header" {
	output=$( load_fixture "file-perms" | $diff_so_fancy )
	refute_output --partial 'diff --git'
}

@test "Reworked hunks" {
	output=$( load_fixture "file-moves" | $diff_so_fancy )
	run printf "%s" "$output"

	assert_line --index 46 --partial "@ package.json:1 @"
	assert_line --index 79 --partial "@ square.yml:1 @"
}

@test "Reworked hunks (noprefix)" {
	output=$( load_fixture "noprefix" | $diff_so_fancy )
	assert_output --partial '@ setup-a-new-machine.sh:33 @'
	assert_output --partial '@ setup-a-new-machine.sh:219 @'
}

@test "Reworked hunks (deleted files)" {
	output=$( load_fixture "dotfiles" | $diff_so_fancy )
	run printf "%s" "$output"

	assert_line --index 188 --partial "@ bin/diff-so-fancy:1 @"
}

@test "Hunk formatting: @@@ -A,B -C,D +E,F @@@" {
	# stderr forced into output
	output=$( load_fixture "complex-hunks" | $diff_so_fancy 2>&1 )
	run printf "%s" "$output"

	assert_line --index 6 --partial "@ libs/header_clean/header_clean.pl:107 @"
	refute_output --partial 'Use of uninitialized value'
}

@test "Hunk formatting: @@ -1,6 +1,6 @@" {
	# stderr forced into output
	output=$( load_fixture "first-three-line" | $diff_so_fancy )
	assert_output --partial '@ package.json:3 @'
}

@test "Hunk formatting: @@ -1 0,0 @@" {
	# stderr forced into output
	output=$( load_fixture "single-line-remove" | $diff_so_fancy )
	run printf "%s" "$output"
	assert_line --index 4 --partial 'var delayedMessage = "It worked";'
}

@test "Three way merge" {
	# stderr forced into output
	output=$( load_fixture "complex-hunks" | $diff_so_fancy )
	# Lines should not have + or - in at the start
	refute_output --partial '-	my $foo = shift(); # Array passed in by reference'
	refute_output --partial '+	my $array = shift(); # Array passed in by reference'
	refute_output --partial ' sub parse_hunk_header {'
}

@test "mnemonicprefix handling" {
	output=$( load_fixture "mnemonicprefix" | $diff_so_fancy )
	assert_output --partial 'modified: test/header_clean.bats'
}

@test "non-git diff parsing" {
	output=$( load_fixture "weird" | $diff_so_fancy )
	run printf "%s" "$output"

	assert_line --index 1 --partial "modified: doc/manual.xml.head"
	assert_line --index 3 --partial "@ doc/manual.xml.head:8355 @"
}
