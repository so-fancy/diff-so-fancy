#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/util'

# bats fails to handle our multiline result, so we save to $output ourselves
output=$( load_fixture "file-moves" | $diff_so_fancy )

@test "Handle file renames" {
	output=$( load_fixture "file-rename" | $diff_so_fancy )
	run printf "%s" "$output"
	assert_line --index 1 --partial "renamed:"
	assert_line --index 1 --partial "Changes.new"
	assert_line --index 1 --partial "bin/"
}

@test "header_clean 'added:'" {
	assert_output --regexp 'added:.*hello.txt'
}

@test "header_clean 'modified:'" {
	assert_output --partial 'modified: appveyor.yml'
}

@test "header_clean 'deleted:'" {
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
	assert_output --partial '@ square.yml:4 @'
	assert_output --partial '@ package.json:1 @'
}

@test "Reworked hunks (noprefix)" {
	output=$( load_fixture "noprefix" | $diff_so_fancy )
	assert_output --partial '@ setup-a-new-machine.sh:33 @'
	assert_output --partial '@ setup-a-new-machine.sh:219 @'
}

@test "Reworked hunks (deleted files)" {
	output=$( load_fixture "dotfiles" | $diff_so_fancy )
	assert_output --partial '@ diff-so-fancy:1 @'
}

@test "Hunk formatting: @@@ -A,B -C,D +E,F @@@" {
	# stderr forced into output
	output=$( load_fixture "complex-hunks" | $diff_so_fancy 2>&1 )
	assert_output --partial '@ header_clean.pl:107 @'
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
	assert_line --index 4 'var delayedMessage = "It worked";'
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
	assert_output --partial 'modified: doc/manual.xml.head'
	assert_output --partial '@ manual.xml.head:8355 @'
}
