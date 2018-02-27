# diff-so-fancy  [![Circle CI build](https://circleci.com/gh/so-fancy/diff-so-fancy.svg?style=svg)](https://circleci.com/gh/so-fancy/diff-so-fancy) [![TravisCI build](https://travis-ci.org/so-fancy/diff-so-fancy.svg?branch=master)](https://travis-ci.org/so-fancy/diff-so-fancy) [![AppVeyor build](https://ci.appveyor.com/api/projects/status/github/so-fancy/diff-so-fancy?branch=master&svg=true)](https://ci.appveyor.com/project/stevemao/diff-so-fancy/branch/master)

`diff-so-fancy` strives to make your diff's **human** readable instead of machine readable. This helps improve code quality and help you spot defects faster.


## Screenshot

Vanilla `git diff` vs `git` and `diff-so-fancy`

![diff-highlight vs diff-so-fancy](https://user-images.githubusercontent.com/3429760/32387617-44c873da-c082-11e7-829c-6160b853adcb.png)

## Install

Installation is as simple as downloading the [diff-so-fancy](https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy) script to a directory in your path.
Windows users may need to install the [Windows subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10).

`diff-so-fancy` is also available from NPM, Nix, brew, and as a package on Arch Linux.

## Usage

Configure git to use `diff-so-fancy` for all diff output:
```shell
git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
```

### Improved colors for the highlighted bits

The default Git colors are not optimal. We suggest the following colors instead.
```shell
git config --global color.ui true

git config --global color.diff-highlight.oldNormal    "red bold"
git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal    "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"

git config --global color.diff.meta       "yellow"
git config --global color.diff.frag       "magenta bold"
git config --global color.diff.commit     "yellow bold"
git config --global color.diff.old        "red bold"
git config --global color.diff.new        "green bold"
git config --global color.diff.whitespace "red reverse"
```

## Options

### markEmptyLines

Should the first block of an empty line be colored. (Default: true)
```
git config --bool --global diff-so-fancy.markEmptyLines false
```

### changeHunkIndicators

Simplify git header chunks to a more human readable format. (Default: true)
```
git config --bool --global diff-so-fancy.changeHunkIndicators false
```

### stripLeadingSymbols

Should the pesky `+` or `-` at line-start be removed. (Default: true)
```
git config --bool --global diff-so-fancy.stripLeadingSymbols false
```

### useUnicodeRuler

By default the separator for the file header uses Unicode line drawing characters. If this is causing output errors on your terminal set this to `false` to use ASCII characters instead. (Default: true)
```
git config --bool --global diff-so-fancy.useUnicodeRuler false
```

## Contributing

Pull requests are quite welcome, and should target the [`next` branch](https://github.com/so-fancy/diff-so-fancy/tree/next). We are also looking for any feedback or ideas on how to make diff-so-fancy even better.

### Other documentation

* [Pro-tips on advanced usage](pro-tips.md)
* [Reporting Bugs](reporting-bugs.md)
* [Hacking and Testing](hacking-and-testing.md)
* [History](history.md)

## License

MIT
