# diff-so-fancy

diff-so-fancy builds on the good-lookin' output of diff-highlight to upgrade
your diffs' appearances.

* Output will not be in standard patch format, but will be readable.
* No pesky `+` or `-` at line-stars, making for easier copy-paste.

## Screenshot

*`git diff` vs `git diff --color | diff-highlight | diff-so-fancy`*

![diff-highlight vs diff-so-fancy](https://cloud.githubusercontent.com/assets/39191/10000682/8e849130-6052-11e5-9bd9-bd4505cd24d6.png)

## Usage

```shell
git diff --color | diff-highlight | diff-so-fancy
```

Add to .gitconfig so all `git diff` uses it.
```shell
git config --global core.pager "diff-highlight | diff-so-fancy | less --tabs=1,5 -R"
```

## Install

```shell
npm install -g diff-so-fancy
```
This will install and link the `diff-so-fancy` and `diff-highlight` scripts.

### GNU sed.
On Mac, install it with Homebrew.
```shell
brew install gnu-sed --with-default-names  # You'll have to change below to `gsed` otherwise
```

### Git config color
```
git config --global color.diff-highlight.oldNormal "red bold"
git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"
```
You may also want to configure [general diff colors](https://github.com/paulirish/dotfiles/blob/63cb8193b0e66cf80ab6332477f1f52c7fbb9311/.gitconfig#L23-L36).

### `diff-highlight`
It's installed via the `diff-so-fancy` npm package. But it's also shipped with
Git so, if you prefer, you can add it to your `$PATH` manually:
```shell
ln -sf "$(brew --prefix)/share/git-core/contrib/diff-highlight/diff-highlight" ~/bin/diff-highlight
# confirm that ~/bin is in your PATH
```


## Credit

Extracted from https://github.com/paulirish/dotfiles/blob/master/bin/diff-so-fancy
