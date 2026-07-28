.PHONY: default build test

default: build

build:
	mkdir -p dist
	perl third_party/build_fatpack/build.pl --output dist/diff-so-fancy

test:
	./test/bats/bin/bats test
