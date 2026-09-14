.PHONY: default build test docs

default: build

build:
	mkdir -p dist
	perl third_party/build_fatpack/build.pl --output dist/diff-so-fancy

test:
	./test/bats/bin/bats test

docs:
	pod2man diff-so-fancy docs/diff-so-fancy.1
