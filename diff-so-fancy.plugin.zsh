# Add our plugin diretory to user's path
#
# See following web page for explanation of the line "ZERO=...":
# https://zdharma-continuum.github.io/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html

0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"
local diff_so_fancy_bin="${0:h}"

if [[ -z "${path[(r)${diff_so_fancy_bin}]}" ]]; then
    path+=( "${diff_so_fancy_bin}" )
fi