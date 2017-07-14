## Pro-tips

#### One-off fanciness or a specific diff-so-fancy alias

You can do also do a one-off or a specific `diff-so-fancy` alias:
```shell
git diff --color | diff-so-fancy

git config --global alias.dsf '!f() { [ -z "$GIT_PREFIX" ] || cd "$GIT_PREFIX" '\
'&& git diff --color "$@" | diff-so-fancy  | less --tabs=4 -RFX; }; f'
```

#### Opting-out

Sometimes you will want to bypass diff-so-fancy. Use `--no-pager` for that:

```shell
git --no-pager diff
```

#### Raw patches

As a shortcut for a 'normal' diff to save as a patch for emailing or later
application, it may be helpful to configure an alias:
```ini
[alias]
    patch = !git --no-pager diff --no-color
```
which can then be used as `git patch > changes.patch`.

#### Moving around in the diff

You can pre-seed your `less` pager with a search pattern, so you can move
between files with `n`/`N` keys:
```ini
[pager]
    diff = diff-so-fancy | less --tabs=4 -RFX --pattern '^(Date|added|deleted|modified): '
```
