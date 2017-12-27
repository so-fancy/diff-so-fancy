set -e
fixtures_dir=$(config fixtures_dir)
diff_so_fancy_bin=$(config diff_so_fancy_bin)
set -x
cat $fixtures_dir/file-rename.diff | $diff_so_fancy_bin
set +x
