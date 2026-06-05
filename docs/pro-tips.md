# Pro-tips

## One-off fanciness or a specific diff-so-fancy alias

You can do also do a one-off:

```shell
git diff --color | diff-so-fancy
```

or configure an alias and a corresponding pager to use `diff-so-fancy`:

```shell
git config --global alias.dsf "diff --color"
git config --global pager.dsf "diff-so-fancy | less --tabs=4 -RFXS"
```

or with long flags:

```shell
git config --global alias.dsf "diff --color"
git config --global pager.dsf "diff-so-fancy | less --tabs=4 --RAW-CONTROL-CHARS --quit-if-one-screen --no-init --chop-long-lines"
```

## Opting-out

Sometimes you will want to bypass diff-so-fancy. Use `--no-pager` for that:

```shell
git --no-pager diff
```

## Raw patches

As a shortcut for a 'normal' diff to save as a patch for emailing or later
application, it may be helpful to configure an alias:

```ini
[alias]
    patch = !git --no-pager diff --no-color
```

which can then be used as `git patch > changes.patch`.

## Improved colors for the highlighted bits

The default Git colors are not optimal. The colors used for the screenshot were:

```shell
git config --global color.ui true

git config --global color.diff-highlight.oldNormal    "red bold"
git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal    "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"

git config --global color.diff.meta       "11"
git config --global color.diff.frag       "magenta bold"
git config --global color.diff.func       "146 bold"
git config --global color.diff.commit     "yellow bold"
git config --global color.diff.old        "red bold"
git config --global color.diff.new        "green bold"
git config --global color.diff.whitespace "red reverse"
```

#### Moving around in the diff

You can pre-seed your `less` pager with a search pattern so that you can move
between files with `n`/`N` keys:

```ini
[pager]
    diff = diff-so-fancy | less --tabs=4 -RFXS --pattern '^(Date|added|deleted|modified): '
```

or with long flags:

```ini
[pager]
    diff = diff-so-fancy | less --tabs=4 --RAW-CONTROL-CHARS --quit-if-one-screen --no-init --chop-long-lines --pattern='^(Date|added|deleted|modified): '
```

## Zsh plugin suppport for diff-so-fancy

This project includes a `diff-so-fancy.plugin.zsh` file providing ZSH framework
support. You can use any framework that supports the ZSH plugin standard to
install `diff-so-fancy` and add it to your `$PATH`. Installation with Zinit,
Zplug, and Zgen:

### Install with zinit

```sh
zinit ice lucid as"program" pick"bin/git-dsf"
zinit load so-fancy/diff-so-fancy
```

### Install with zplug

```sh
zplug "so-fancy/diff-so-fancy", as:command, use:bin/git-dsf
```

### zgenom and others

```sh
zgenom load so-fancy/diff-so-fancy
```

## `hg` configuration

You can configure `hg diff` output to use `diff-so-fancy` by adding this alias
to your `hgrc` file:

```ini
[alias]
    diff = !HGPLAIN=1 $HG diff --pager=on --config pager.pager=diff-so-fancy $@
```
