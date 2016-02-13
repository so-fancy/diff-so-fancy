# diff-so-fancy  [![Circle CI build](https://circleci.com/gh/stevemao/diff-so-fancy.svg?style=svg)](https://circleci.com/gh/stevemao/diff-so-fancy)

diff-so-fancy builds on the good-lookin' output of [git contrib](https://github.com/git/git/tree/master/contrib)'s [diff-highlight](https://github.com/git/git/tree/master/contrib/diff-highlight) to upgrade
your diffs' appearances.

* Output will not be in standard patch format, but will be readable.
* No pesky `+` or `-` at line-stars, making for easier copy-paste.

## Screenshot

*`git diff` vs `git diff --color | diff-so-fancy`*

![diff-highlight vs diff-so-fancy](https://cloud.githubusercontent.com/assets/39191/10000682/8e849130-6052-11e5-9bd9-bd4505cd24d6.png)

## Usage

You can do one-off fanciness:
```shell
git diff --color | diff-so-fancy
```

**But**, you'll probably want to fancify all your diffs. Run this so `git diff` and `git show` will use it:
```shell
git config --global pager.diff "diff-so-fancy | less --tabs=1,5 -R"
git config --global pager.show "diff-so-fancy | less --tabs=1,5 -R"
```

Or, create a git alias  in your `~/.gitconfig` for shorthand fanciness:
```shell
dsf = "!git diff --color $@ | diff-so-fancy"
```

## Install

For convenience, the recommended installation is via NPM:
```shell
npm install -g diff-so-fancy
```
This will install and link the `diff-so-fancy` and `diff-highlight` scripts.

### Manual installation alternative

If you want, you can choose to install manually:

* Grab the two scripts (`diff-highlight` and `diff-so-fancy`) via either downloading or cloning the repo.
* If you download `diff-highlight` from the official git repo, make sure it's executable.
* Symlink or place them in a location that is in your `PATH`.
* Set up the git `pager.diff` and `pager.show` configs, as described above.

Note: The `diff-highlight` dependency is an [official git-contrib script](https://github.com/git/git/tree/master/contrib/diff-highlight), duplicated here for convenience. If you prefer less fancy in your diff, you also use diff-highlight [on it's own](https://news.ycombinator.com/item?id=11068436).

### Install GNU `sed`

You'll need GNU sed. On Mac, it's easy to install with Homebrew.
```shell
brew install gnu-sed
```

### Improved colors for the highlighted bits

`diff-highlight` has default colors that are arguably a little nasty. They'll work fine, but you can try some fancier colors:
```shell
git config --global color.diff-highlight.oldNormal "red bold"
git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"
```
You may also want to configure [general diff colors](https://github.com/paulirish/dotfiles/blob/63cb8193b0e66cf80ab6332477f1f52c7fbb9311/.gitconfig#L23-L36).

## Opting-out

Sometimes you will want to bypass diff-so-fancy. Use `--no-pager` for that:

```shell
git --no-pager diff
```


## Credit

Originated from https://github.com/paulirish/dotfiles/blob/master/bin/diff-so-fancy

## Contributing

Pull requests quite welcome.

## Hacking and Testing

Install [bats](github.com/sstephenson/bats#installing-bats-from-source), the Bash automated testing system we are using.

```sh
# fork and clone the repo. then…
git submodule update --init
```

```sh
# Run the test suite once:
bats test/diff-so-fancy.bats

# Run it on every change with `entr`
brew install entr
ls --color=never diff-so-fancy test/*.bats | entr bats test/*.bats
```

## License

MIT
