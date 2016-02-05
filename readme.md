# diff-so-fancy

diff-so-fancy builds on the good-lookin' output of diff-highlight to upgrade your diffs' appearances
* Output will not be in standard patch format, but will be readable
* No pesky `+` or `-` at line-stars, making for easier copy-paste.

## Screenshot

*diff-highlight (default) vs diff-so-fancy*

![diff-highlight vs diff-so-fancy](https://cloud.githubusercontent.com/assets/39191/10000682/8e849130-6052-11e5-9bd9-bd4505cd24d6.png)

## Usage

```shell
git diff | diff-highlight | diff-so-fancy
```

Add to .gitconfig so all `git diff` uses it.
```shell
git config --global core.pager "diff-highlight | diff-so-fancy | less -r"
```

## Install

GNU sed. On Mac, install it with Homebrew:
```shell
brew install gnu-sed --with-default-names  # You'll have to change below to `gsed` otherwise
```

diff-highlight. It's shipped with Git, but probably not in your `$PATH`:
```shell
ln -sf "$(brew --prefix)/share/git-core/contrib/diff-highlight/diff-highlight" ~/bin/diff-highlight
```

Add some coloring to your .gitconfig:
```
git config --global color.diff-highlight.oldNormal "red bold"
git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"
```

### npm

```shell
npm install -g diff-so-fancy
```

## Credit

Extracted from https://github.com/paulirish/dotfiles/blob/master/bin/diff-so-fancy
