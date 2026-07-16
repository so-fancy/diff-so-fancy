#!/usr/bin/env bats

# Tests for the OSC 1717 diff-line-metadata protocol (see
# diff-line-metadata-osc-spec.md). diff-so-fancy strips the +/- markers and
# conveys the side by color, so a host that renders its output cannot recover a
# row's patch identity by parsing it -- the pager states it inline instead. The
# protocol is gated on the OSC1717 handshake and is strictly additive: with the
# variable unset, output is byte-for-byte unchanged.

__load_imports__() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'
	load 'test_helper/util'
}

setup() {
	__load_imports__
	set_env
	setup_default_dsf_git_config
}

teardown() {
	teardown_default_dsf_git_config
}

# Extract the OSC 1717 payloads (everything between "ESC ] 1717 ;" and the
# string terminator) from stdin, one record per line, for line-wise assertions.
all_osc_records() {
	perl -ne 'while (/\e\]1717;([^\e\a]*)(?:\e\\|\a)/g) { print "$1\n"; }'
}

# As all_osc_records, but skips the version-only handshake record (no fields; see
# the dedicated handshake tests), so per-line assertions stay focused on content.
osc_records() {
	all_osc_records | perl -ne 'print if /;/;'
}

# Render a fixture with the host handshake set to V1, returning just the records.
records_for() {
	load_fixture "$1" | OSC1717=V1 "$diff_so_fancy" | osc_records
}

# As records_for, but only the content-line records (c/a/d), skipping the f/h
# header records, so tests about content-line semantics stay independent of how
# many rows the rendered header blocks span.
content_records_for() {
	records_for "$1" | perl -ne 'print if /^\d+;[cad];/;'
}

@test "no metadata is emitted without the handshake" {
	output=$( load_fixture "ls-function" | $diff_so_fancy | osc_records )
	assert_output ""
}

@test "the handshake negotiates the protocol version" {
	# A version we don't emit -> silence (the advertised set is disjoint).
	output=$( load_fixture "add_file_with_content" | OSC1717=V2 "$diff_so_fancy" | osc_records )
	assert_output ""

	# Junk -> silence.
	output=$( load_fixture "add_file_with_content" | OSC1717=nonsense "$diff_so_fancy" | osc_records )
	assert_output ""

	# A list that includes V1 -> V1 records (we emit the highest we both know).
	output=$( load_fixture "add_file_with_content" | OSC1717=V0,V1,V2 "$diff_so_fancy" | osc_records )
	run printf "%s" "$output"
	assert_line --index 0 "1;f;;;newfile.txt"
}

@test "a version-only handshake is emitted first, before any per-line record" {
	# The handshake (just the version, no further fields) announces protocol support;
	# it precedes the per-line records so a host sees it up front.
	output=$( load_fixture "add_file_with_content" | OSC1717=V1 "$diff_so_fancy" | all_osc_records )
	run printf "%s" "$output"
	assert_line --index 0 "1"
	assert_line --index 1 "1;f;;;newfile.txt"
}

@test "the handshake is emitted even for an empty diff, so a host can probe" {
	# An empty diff has no content lines and so no per-line records; the handshake is
	# still emitted, letting a host probe diff-so-fancy with empty input.
	output=$( printf "" | OSC1717=V1 "$diff_so_fancy" | all_osc_records )
	assert_output "1"
}

@test "added lines carry the new-file line and an empty old-file field" {
	output=$( content_records_for "add_file_with_content" )
	run printf "%s" "$output"
	assert_line --index 0 "1;a;1;;newfile.txt"
	assert_line --index 1 "1;a;2;;newfile.txt"
	assert_line --index 2 "1;a;3;;newfile.txt"
}

@test "deleted lines carry both line numbers; a whole-file delete sits at new-line 0" {
	output=$( content_records_for "delete_file_with_content" )
	run printf "%s" "$output"
	assert_line --index 0 "1;d;0;1;oldfile.txt"
	assert_line --index 1 "1;d;0;2;oldfile.txt"
	assert_line --index 2 "1;d;0;3;oldfile.txt"
}

@test "the path falls back to the old side for a noprefix deletion" {
	# This fixture's "diff --git" line has no a/ b/ prefix and the +++ side is
	# /dev/null, so the path is recoverable only from the --- (old) side.
	output=$( content_records_for "single-line-remove" )
	assert_output "1;d;0;1;test/data/readywaitasset.js"
}

@test "context, deletion and addition interleave; the no-newline marker is skipped" {
	# one/two are context; "three" is modified (delete then add at new-line 3).
	# The trailing "\ No newline at end of file" carries no record and does not
	# advance the counters.
	output=$( content_records_for "remove_slashn_eof" )
	run printf "%s" "$output"
	assert_line --index 0 "1;c;1;;test.txt"
	assert_line --index 1 "1;c;2;;test.txt"
	assert_line --index 2 "1;d;3;3;test.txt"
	assert_line --index 3 "1;a;3;;test.txt"
	refute_line "1;c;4;;test.txt"
}

@test "combined (merge) diffs carry only their file header's f record" {
	# A combined diff (@@@ ...) has multiple old-file sides and a different
	# line-number model, so its hunks and content lines are not annotated. The
	# file header still carries its `f` record (one per row of the ruled
	# block), so the file stays visible to a host's file list/navigation.
	output=$( records_for "complex-hunks" )
	run printf "%s" "$output"
	assert_output "1;f;;;libs/header_clean/header_clean.pl
1;f;;;libs/header_clean/header_clean.pl
1;f;;;libs/header_clean/header_clean.pl"
}

@test "file headers carry f records on every row; hunk headers carry h with the hunk's first line" {
	# file-rename.diff renames Changes.new (no content change) and then
	# modifies dist.ini in two hunks (@@ -1,4 +1,4 @@ and @@ -9,6 +9,7 @@).
	output=$( records_for "file-rename" )
	run printf "%s" "$output"

	# The pure rename emits only its `f` records -- one per row of the ruled
	# header block, no line numbers (spec §5.5) -- keeping a file with no
	# content lines visible to the host.
	assert_line --index 0 "1;f;;;bin/Changes.new"
	assert_line --index 1 "1;f;;;bin/Changes.new"
	assert_line --index 2 "1;f;;;bin/Changes.new"

	# The modified file: its own `f` block, then each hunk's row carries `h`
	# with the hunk's first new-file line (the @@ new start, not the first
	# changed line the rendered header displays).
	assert_line --index 3 "1;f;;;dist.ini"
	assert_line --index 6 "1;h;1;;dist.ini"
	assert_line --index 7 "1;d;1;1;dist.ini"
	assert_line "1;h;9;;dist.ini"
}

@test "a mode-only change carries an f record on its single announcement row" {
	# circle.yml only changes its mode; "circle.yml changed file mode ..." is
	# the only row announcing it, so that row carries the `f`. foo.json is a
	# regular added file whose header follows as its own f block.
	output=$( records_for "file-perms" )
	run printf "%s" "$output"
	assert_line --index 0 "1;f;;;circle.yml"
	assert_line --index 1 "1;f;;;foo.json"
	assert_line --index 4 "1;h;1;;foo.json"
	assert_line --index 5 "1;a;1;;foo.json"
}

@test "binary files carry an f record" {
	# A binary file emits no content records; its `f` keeps it visible.
	output=$( records_for "binary-modified" )
	run printf "%s" "$output"
	assert_line --index 0 "1;f;;;cancel.png"
}

@test "content records stop at the hunk's counted extent" {
	# The @@ counts are exact, so the records must end with the hunk. The
	# submodule log lines that follow ("  > subject") begin with a space and
	# would otherwise be classified as context lines carrying the previous
	# hunk's (stale) file and line numbers.
	output=$( content_records_for "submodule-log" )
	run printf "%s" "$output"
	assert_line --index 0 "1;d;1;1;one.txt"
	assert_line --index 1 "1;a;1;;one.txt"
	refute_line --partial ";c;"
}

@test "diffstat and commit-message lines after a hunk carry no records" {
	# In `git log -p` output, the next commit's indented message body and its
	# diffstat lines also begin with a space; none of them are content lines
	# of the preceding hunk.
	output=$( content_records_for "log-with-stat" )
	run printf "%s" "$output"
	assert_line --index 0 "1;d;1;1;one.txt"
	assert_line --index 1 "1;a;1;;one.txt"
	refute_line --partial ";c;"
}
