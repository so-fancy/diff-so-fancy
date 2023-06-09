
diff_so_fancy="$BATS_TEST_DIRNAME/../diff-so-fancy"

load_fixture() {
  local name="$1"
  cat "$BATS_TEST_DIRNAME/fixtures/${name}.diff"
}

set_env() {
  export LC_CTYPE="en_US.UTF-8"
}

dsf_test_git_config() {
  printf '%s/gitconfig' "${BATS_TMPDIR}"
}

# applying colors so ANSI color values will match
# FIXME: not everyone will have these set, so we need to test for that.
setup_default_dsf_git_config() {
  GIT_CONFIG="$(dsf_test_git_config)" || return $?
  cat > "${GIT_CONFIG}" <<EOF || return $?
[color "diff"]
	meta = 227
	frag = magenta bold
	commit = 227 bold
	old = red bold
	new = green bold
	whitespace = red reverse
	func = brightyellow

[color "diff-highlight"]
	oldNormal = red bold
	oldHighlight = red bold 52
	newNormal = green bold
	newHighlight = green bold 22
EOF
  export GIT_CONFIG
  export GIT_CONFIG_NOSYSTEM=1
}

teardown_default_dsf_git_config() {
  local test_config
  test_config="$(dsf_test_git_config)" || return $?
  [ ! -f "${test_config}" ] || rm -f "${test_config}"
  GIT_CONFIG=/dev/null
}
