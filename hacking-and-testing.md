### Hacking

```sh
# fork and clone the diff-so-fancy repo.
git clone https://github.com/so-fancy/diff-so-fancy/ && cd diff-so-fancy

# test a saved diff against your local version
cat test/fixtures/ls-function.diff | ./diff-so-fancy

# setup symlinks to use local copy
npm link
cd ~/projects/catfabulator && git diff
```

### Running tests

You'll need to install [bats](https://github.com/sstephenson/bats#installing-bats-from-source), the Bash automated testing system. It's also available as `brew install bats`

```sh
git submodule sync
git submodule update --init # pull in the assertion library, bats-assert

# run the test suite once:
bats test

# run it on every change with `entr`
brew install entr
ls --color=never diff-so-fancy test/*.bats | entr bats test
```
When writing assertions, you'll likely want to compare to expected output. To grab that reliably, you can use something like `git --no-pager diff | diff-so-fancy > output.txt`

You can lint your scripts via shellcheck, our CI bots will also check.

```sh
brew install shellcheck
shellcheck diff-so-fancy update-deps.sh
