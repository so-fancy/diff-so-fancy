#!/usr/bin/env bash
#
# diff-so-fancy install script
#
# diff-so-fancy builds on the good-lookin' output of git contrib's
# diff-highlight to upgrade your diffs' appearances.
#
# Output will not be in standard patch format, but will be readable.
# No pesky + or - at line-start, making for easier copy-paste.
#
# largely inspired by nvm's install script

GREEN=`tput setaf 2`
RED=`tput setaf 1`
NC=`tput sgr0` # No Color
UNDERLINE=`tput smul`
BOLD=`tput bold`
INSTALL_DIR=

{ # this ensures the entire script is downloaded #

dsf_has() {
    type "$1" > /dev/null 2>&1
}

dsf_latest_version() {
    echo "v0.11.4"
}

dsf_download() {
    if dsf_has "curl"; then
        curl -q "$@"
    elif dsf_has "wget"; then
        # Emulate curl with wget
        ARGS=$(echo "$*" | command sed -e 's/--progress-bar /--progress=bar /' \
                                   -e 's/-L //' \
                                   -e 's/-I /--server-response /' \
                                   -e 's/-s /-q /' \
                                   -e 's/-o /-O /' \
                                   -e 's/-C - /-c /')
        # shellcheck disable=SC2086
        eval wget $ARGS
    fi
}

dsf_download_file() {
    local source_url="https://raw.githubusercontent.com/so-fancy/diff-so-fancy/$(dsf_latest_version)"
    local param_array=("$@")

    # Array content
    # 0 source file (will be concatenated to the url)
    # 1 destination file (used as passed in)
    # 2 string that if equal to "exec" will set chmod +x
    local param_src="${param_array[0]}"
    local param_dst="${param_array[1]}"
    local param_mod="${param_array[2]}"

    echo -en "${BOLD}Download $param_src: ${NC}"

    dsf_download -s "$source_url/$param_src" -o "$param_dst" || {
        echo -e "${BOLD}${RED}KO${NC}"
        echo -e >&2 "${BOLD}${RED}Failed to download '$source_url/$param_src' to '$param_dst'${NC}\nPlease try again."
        exit 2
    }
    if [ "exec" = "$param_mod" ]; then
        chmod a+x "$param_dst" || {
            echo -e >&2 "${RED}Failed to mark '$param_dst' as executable${NC}"
            exit 3
        }
    fi
    echo -e "${BOLD}${GREEN}OK${NC}"
}

dsf_install_dir() {
    local dirs=("$HOME/bin" "/usr/local/bin");
    local writable=
    local in_path=

    for d in "${dirs[@]}"; do
        in_path=
        writable=

        echo -en "${BOLD}Check if '$d' is writable: "

        if [[ -w "$d" ]]; then
            echo -e "${GREEN}OK${NC}"
            writable="yes"
        else
            echo -e "${RED}KO${NC}"
        fi

        echo -en "${BOLD}Check if '$d' is in PATH: "

        if [[ "$PATH" =~ $d ]]; then
            echo -e "${GREEN}OK${NC}"
            in_path="yes"
        else
            echo -e "${RED}KO${NC}"
        fi

        if [[ "$writable" == "yes" && "$in_path" == "yes" ]]; then
            INSTALL_DIR=$d
            break
        fi
    done

    if [ -z "$INSTALL_DIR" ]; then
        echo -e >&2 "${BOLD}${RED}The default install directories could not be used.${NC}\nTry to fix the problem or call the script with sudo."
        exit 4
    fi
}

dsf_install_as_script() {
    local files1=("diff-so-fancy" "$INSTALL_DIR/diff-so-fancy" "exec")
    local files2=("third_party/diff-highlight/diff-highlight" "$INSTALL_DIR/diff-highlight" "exec")

    # Checking if it has already been installed
    if [ -f "$INSTALL_DIR/${files1[0]}" ]; then
        echo -e >&2 "${BOLD}${RED}The diff-so-fancy script is already installed in '$INSTALL_DIR'${NC}.\nTry to delete '$INSTALL_DIR/${files1[0]}' and try again.${NC}"
        exit 1
    else
        dsf_download_file "${files1[@]}"
        dsf_download_file "${files2[@]}"
    fi
}

dsf_do_install() {

    if ! dsf_has dsf_download; then
        echo >&2 "You need curl or wget to install diff-so-fancy";
        exit 1
    fi

    dsf_install_dir

    dsf_install_as_script
}

    TXT="
${BOLD}${GREEN}Successfully installed${NC}

Now you can do one-off fanciness:

  ${BOLD}git diff --color | diff-so-fancy${NC}

${UNDERLINE}But${NC}, you'll probably want to fancify all your diffs. Set your core.pager to run diff-so-fancy, and pipe the output through your existing pager, or if unset we recommend less --tabs=4 -RFX:

  ${BOLD}git config --global core.pager \"diff-so-fancy | less --tabs=4 -RFX\"${NC}

However, if you'd prefer to do the fanciness on-demand with git dsf, add an alias to your ~/.gitconfig by running:

  ${BOLD}git config --global alias.dsf '!f() { [ -z \"\$GIT_PREFIX\" ] || cd \"\$GIT_PREFIX\" '\\
  '&& git diff --color "$@" | diff-so-fancy  | less --tabs=4 -RFX; }; f'${NC}

Enjoy!"


dsf_do_install

if [ $# -eq 0 ]; then
    printf "%-10s\n" "$TXT"
fi

} # this ensures the entire script is downloaded #
