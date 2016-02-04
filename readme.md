###############
# diff-so-fancy builds on the good-lookin' output of diff-highlight to upgrade your diffs' appearances
# 	* Output will not be in standard patch format, but will be readable
#   * No pesky `+` or `-` at line-stars, making for easier copy-paste.
#
# Screenshot: https://github.com/paulirish/dotfiles/commit/6743b907ff58#commitcomment-13349456
#
#
# Usage
#
#   git diff | diff-highlight | diff-so-fancy
#
# Add to .gitconfig so all `git diff` uses it.
#   git config --global core.pager "diff-highlight | diff-so-fancy | less -r"
#
#
# Requirements / Install
#
# * GNU sed. On Mac, install it with Homebrew:
#   	brew install gnu-sed --default-names  # You'll have to change below to `gsed` otherwise
# * diff-highlight. It's shipped with Git, but probably not in your $PATH
#       ln -sf "$(brew --prefix)/share/git-core/contrib/diff-highlight/diff-highlight" ~/bin/diff-highlight
# * Add some coloring to your .gitconfig:
#		git config --global color.diff-highlight.oldNormal "red bold"
#		git config --global color.diff-highlight.oldHighlight "red bold 52"
#		git config --global color.diff-highlight.newNormal "green bold"
#		git config --global color.diff-highlight.newHighlight "green bold 22"
#
###############

# npm
#   npm install -g diff-so-fancy

Extracted from https://github.com/paulirish/dotfiles/blob/master/bin/diff-so-fancy
