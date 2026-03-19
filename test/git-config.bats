#!/usr/bin/env bats

# Used by both `setup_file` and `setup`, which are special bats callbacks.
__load_imports__() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'
	load 'test_helper/util'
}

# ansi related values
escape=$'\e'
ansi_bold=1
ansi_dim=2
ansi_ul=4
ansi_reverse=7

# hash of colors
declare -Ag ansi_colors=(
    [black]='0'
    [red]='1'
    [green]='2'
    [yellow]='3'
    [blue]='4'
    [magenta]='5'
    [cyan]='6'
    [white]='7'
    [default]='9'
)

# get a foreground or background color code
ansi_color() {
    color=$1
    incr=$2
    base_code=$((30+$incr))

    # handle bright prefix
    if [[ "${1}" =~ (bright)(.*) ]]
    then
        color=${BASH_REMATCH[2]}
        base_code=$((90+$incr))
    fi
    code=$(($base_code+${ansi_colors[$color]}))
    echo "$code"
}

# get a foreground color code
fg_color() {
    ansi_color $1 0
}

# get a background color code
bg_color() {
    ansi_color $1 10
}

# get rgb color codes from hex
rgb_color() {
    incr=$2
    base_code=$((38+$incr))
    [[ $1 =~ ^.(..)(..)(..)$ ]]
    rgb1="${BASH_REMATCH[1]}"
    rgb2="${BASH_REMATCH[2]}"
    rgb3="${BASH_REMATCH[3]}"
    echo "${base_code};2;$(( 16#${rgb1} ));$(( 16#${rgb2} ));$(( 16#${rgb3} ))"
}

# get a foreground color code
fg_rgb_color() {
    rgb_color $1 0
}

# get a background color code
bg_rgb_color() {
    rgb_color $1 10
}

# build config using passed in values
setup_dsf_git_config() {
  GIT_CONFIG="$(dsf_test_git_config)" || return $?
  cat > "${GIT_CONFIG}" <<EOF || return $?
[color "diff"]
$1

EOF
  export GIT_CONFIG
  export GIT_CONFIG_NOSYSTEM=1
}

setup_file() {
	__load_imports__
	# setup_default_dsf_git_config
}

setup() {
	__load_imports__
}

teardown_file() {
	teardown_default_dsf_git_config
}

# General description of how colors are applied
# meta = header
# frag = @ filenames
# func = function name after frag
# old  = - lines
# new  = + lines

@test "Test color attributes are removed" {
    config="
	meta = bold ul blink italic strike green no-reverse
	frag = nobold nodim noul noblink noreverse noitalic nostrike blue white
	func = dim reverse white purple
	old = no-bold no-dim no-ul no-blink no-reverse no-italic no-strike red yellow
	new = brightgreen
	whitespace = red reverse
    "
    setup_dsf_git_config "$config"

	output=$( load_fixture "leading-dashes" | $diff_so_fancy )
	run printf "%s" "$output"

    fg_green=$(fg_color green)
    fg_blue=$(fg_color blue)
    fg_red=$(fg_color red)
    fg_brightgreen=$(fg_color brightgreen)
    bg_white=$(bg_color white)
    bg_yellow=$(bg_color yellow)

    assert_line --index 0 --partial  "${escape}[${ansi_bold};${ansi_ul};${fg_green}m"
    assert_line --index 3 --partial  "${escape}[${fg_blue};${bg_white}m@"
    assert_line --index 6 --partial  "${escape}[${fg_red};${bg_yellow}m--"
    assert_line --index 7 --partial  "${escape}[${fg_brightgreen}m--"
}

@test "Test normal and default git colors" {
    config="
	frag = normal default
	old = default
    "
    setup_dsf_git_config "$config"

	output=$( load_fixture "leading-dashes" | $diff_so_fancy )
	run printf "%s" "$output"

    fg_default=$(fg_color default)
    bg_default=$(bg_color default)

    assert_line --index 3 --partial  "${escape}[${bg_default}m@"
    assert_line --index 6 --partial  "${escape}[${fg_default}m--"
}

# Special characters in git config must be quoted (word or all values)
@test "Test rgb git colors" {
    rgb="#408050"
    config="
	frag = \"${rgb}\" default
	old = normal \"${rgb}\"
    "
    setup_dsf_git_config "$config"

	output=$( load_fixture "leading-dashes" | $diff_so_fancy )
	run printf "%s" "$output"

    fg_rgb=$(fg_rgb_color "${rgb}")
    bg_default=$(bg_color default)
    bg_rgb=$(bg_rgb_color "${rgb}")

    assert_line --index 3 --partial  "${escape}[${fg_rgb};${bg_default}m@"
    assert_line --index 6 --partial  "${escape}[${bg_rgb}m--"
}
