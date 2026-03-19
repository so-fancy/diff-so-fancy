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

The tests use [bats-core](https://bats-core.readthedocs.io/en/latest/index.html), the Bash automated testing system.

```sh
# initialize the bats components
git submodule sync && git submodule update --init

# run the test suite once:
./test/bats/bin/bats test

# run it on every change with `entr`
brew install entr
find  ./* test/* test/fixtures/* -maxdepth 0 | entr ./test/bats/bin/bats test
```

When writing assertions, you'll likely want to compare to expected output. To grab that reliably, you can use something like `git --no-pager diff | ./diff-so-fancy > output.txt`


### Publishing to npm

Run these one-by-one, manually.

```sh
diff-so-fancy --version # see the old version (probably)

npm run build  # build the fatpack into dist.

./dist/diff-so-fancy --version # get latest version from perl script

npm version vX.X.X   # bump package.json to match.

npm uninstall -g diff-so-fancy && npm link  # make global symlink, if not already present

diff-so-fancy --version  # ensure latest version is shown

git show | diff-so-fancy  # ensure it works

npm publish --dry-run # ensure listed files are what you want published. update .npmignore as desired

# npm login --registry https://registry.npmjs.org/  # maybe.

npm publish --registry https://registry.npmjs.org/
```

