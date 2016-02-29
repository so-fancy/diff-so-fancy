#!/usr/bin/env bats

load 'test_helper/bats-core/load'
load 'test_helper/bats-assert/load'
load 'test_helper/util'


# bats fails to handle our multiline result, so we save to $output ourselves
output=$( load_fixture "file-moves" | $diff_so_fancy )

@test "header_clean 'added:'" {
	assert_output --partial 'added: hello.txt'
}

@test "header_clean 'modified:'" {
	assert_output --partial 'modified: appveyor.yml'
}

@test "header_clean 'deleted:'" {
	assert_output --partial 'deleted: circle.yml'
}
