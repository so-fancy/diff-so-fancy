### Reporting bugs

If you find a bug using the following command

```sh
git diff HEAD..HEAD^
```

You can use [report-bug.sh](./report-bug.sh) we provide

```sh
./report-bug.sh 'git diff HEAD..HEAD^'

# or

curl https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/report-bug.sh | bash -s 'git diff HEAD..HEAD^' 'diff.txt'
```

Grab the output file and attach to the GitHub issue you create. A base64 version is also copied to your clipboard so you can paste to the issue.
