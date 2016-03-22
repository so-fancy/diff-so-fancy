
diff_so_fancy="$BATS_TEST_DIRNAME/../diff-so-fancy"

load_fixture() {
  local name="$1"
  cat "$BATS_TEST_DIRNAME/fixtures/${name}.diff"
}
