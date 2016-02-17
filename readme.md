# diff-so-fancy  [![Circle CI build](https://circleci.com/gh/so-fancy/diff-so-fancy.svg?style=svg)](https://circleci.com/gh/so-fancy/diff-so-fancy) [![TravisCI build](https://travis-ci.org/so-fancy/diff-so-fancy.svg?branch=master)](https://travis-ci.org/so-fancy/diff-so-fancy) [![AppVeyor build](https://ci.appveyor.com/api/projects/status/github/so-fancy/diff-so-fancy?branch=master&svg=true)](https://ci.appveyor.com/project/stevemao/diff-so-fancy/branch/master)

diff-so-fancy builds on the good-lookin' output of [git contrib](https://github.com/git/git/tree/master/contrib)'s [diff-highlight](https://github.com/git/git/tree/master/contrib/diff-highlight) to upgrade
your diffs' appearances.

* Output will not be in standard patch format, but will be readable.
* No pesky `+` or `-` at line-start, making for easier copy-paste.

## Screenshot

*`git diff` vs `git diff --color | diff-so-fancy`*

![diff-highlight vs diff-so-fancy](https://cloud.githubusercontent.com/assets/39191/10000682/8e849130-6052-11e5-9bd9-bd4505cd24d6.png)

## Usage

You can do one-off fanciness:
```shell
git diff --color | diff-so-fancy
```

**But**, you'll probably want to fancify all your diffs. Run this so `git diff` (and `git show`) will use it:
```shell
git config --global pager.diff "diff-so-fancy | less --tabs=1,5 -RFX"
git config --global pager.show "diff-so-fancy | less --tabs=1,5 -RFX"
```

However, if you'd prefer to do the fanciness on-demand with `git dsf`, drop an alias in your `~/.gitconfig`:
```shell
dsf = "!git diff --color $@ | diff-so-fancy"
```

## Install

For convenience, the recommended installation is via NPM. If you'd prefer, you may choose to do a [manual installation](#manual-install) instead.
```shell
npm install -g diff-so-fancy
```
This will install and link the `diff-so-fancy` and `diff-highlight` scripts.

On Mac, you can install via Homebrew:
```shell
brew update
brew install diff-so-fancy
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


## Manual install

If you want, you can choose to install manually:

1. Grab the two scripts (`diff-highlight` and `diff-so-fancy`) via either downloading or cloning the repo.
1. If you download `diff-highlight` from the official git repo, give it a `chmod +x`.
1. Place them in a location that is in your `PATH` directly or with symlinks.
1. Set up the git `pager.diff` and `pager.show` configs, as described above.

Note: The `diff-highlight` dependency is an [official git-contrib script](https://github.com/git/git/tree/master/contrib/diff-highlight), duplicated here for convenience. If you prefer less fancy in your diff, you also use diff-highlight [on it's own](https://news.ycombinator.com/item?id=11068436).


## Opting-out

Sometimes you will want to bypass diff-so-fancy. Use `--no-pager` for that:

```shell
git --no-pager diff
```


## History

`diff-so-fancy` started as [a commit in paulirish's dotfiles](https://github.com/paulirish/dotfiles/commit/6743b907ff586c28cd36e08d1e1c634e2968893e#commitcomment-13349456), which grew into a [standalone script](https://github.com/paulirish/dotfiles/blob/63cb8193b0e66cf80ab6332477f1f52c7fbb9311/bin/diff-so-fancy). Later, [@stevemao](https://github.com/stevemao) brought it into its [own repo](https://github.com/so-fancy/diff-so-fancy) (here), and gave it the room to mature. It's quickly grown into a [widely collaborative project](https://github.com/so-fancy/diff-so-fancy/graphs/contributors).

## Contributing

Pull requests quite welcome, along with any feedback or ideas.

### Hacking

```sh
# fork and clone the diff-so-fancy repo.
git clone https://github.com/so-fancy/diff-so-fancy/ && cd diff-so-fancy

# test a saved diff against your local version
cat test/fixtures/ls-function.diff  | ./diff-so-fancy

# setup symlinks to use local copy
npm link
cd ~/projects/catfabulator && git diff
```

### Running tests

You'll need to install [bats](https://github.com/sstephenson/bats#installing-bats-from-source), the Bash automated testing system. It's also available as `brew install bats`

```sh
git submodule update --init  # pull in the assertion library, bats-assert

# Run the test suite once:
bats test

# Run it on every change with `entr`
brew install entr
ls --color=never diff-so-fancy test/*.bats | entr bats test
```

Be sure to lint your scripts via shellcheck

```sh
brew install shellcheck
shellcheck diff-so-fancy update-deps.sh
```

## License

MIT
