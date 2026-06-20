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
	assert_line --index 0 "1;a;1;;newfile.txt"
}

@test "a version-only handshake is emitted first, before any per-line record" {
	# The handshake (just the version, no further fields) announces protocol support;
	# it precedes the per-line records so a host sees it up front.
	output=$( load_fixture "add_file_with_content" | OSC1717=V1 "$diff_so_fancy" | all_osc_records )
	run printf "%s" "$output"
	assert_line --index 0 "1"
	assert_line --index 1 "1;a;1;;newfile.txt"
}

@test "the handshake is emitted even for an empty diff, so a host can probe" {
	# An empty diff has no content lines and so no per-line records; the handshake is
	# still emitted, letting a host probe diff-so-fancy with empty input.
	output=$( printf "" | OSC1717=V1 "$diff_so_fancy" | all_osc_records )
	assert_output "1"
}

@test "added lines carry the new-file line and an empty old-file field" {
	output=$( records_for "add_file_with_content" )
	run printf "%s" "$output"
	assert_line --index 0 "1;a;1;;newfile.txt"
	assert_line --index 1 "1;a;2;;newfile.txt"
	assert_line --index 2 "1;a;3;;newfile.txt"
}

@test "deleted lines carry both line numbers; a whole-file delete sits at new-line 0" {
	output=$( records_for "delete_file_with_content" )
	run printf "%s" "$output"
	assert_line --index 0 "1;d;0;1;oldfile.txt"
	assert_line --index 1 "1;d;0;2;oldfile.txt"
	assert_line --index 2 "1;d;0;3;oldfile.txt"
}

@test "the path falls back to the old side for a noprefix deletion" {
	# This fixture's "diff --git" line has no a/ b/ prefix and the +++ side is
	# /dev/null, so the path is recoverable only from the --- (old) side.
	output=$( records_for "single-line-remove" )
	assert_output "1;d;0;1;test/data/readywaitasset.js"
}

@test "context, deletion and addition interleave; the no-newline marker is skipped" {
	# one/two are context; "three" is modified (delete then add at new-line 3).
	# The trailing "\ No newline at end of file" carries no record and does not
	# advance the counters.
	output=$( records_for "remove_slashn_eof" )
	run printf "%s" "$output"
	assert_line --index 0 "1;c;1;;test.txt"
	assert_line --index 1 "1;c;2;;test.txt"
	assert_line --index 2 "1;d;3;3;test.txt"
	assert_line --index 3 "1;a;3;;test.txt"
	refute_line "1;c;4;;test.txt"
}

@test "combined (merge) diffs are not annotated" {
	# A combined diff (@@@ ...) has multiple old-file sides and a different
	# line-number model, so no records are emitted for it.
	output=$( records_for "complex-hunks" )
	assert_output ""
}
