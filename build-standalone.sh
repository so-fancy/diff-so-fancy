#!/bin/bash

function has-cmd() {  command -v "$1" > /dev/null; }
function no-cmd() { ! command -v "$1" > /dev/null; }

if no-cmd fatpack && has-cmd apt; then
  sudo apt install libapp-fatpacker-perl
fi

THIS_DIR="$(git rev-parse --show-toplevel)"
OUTPUT="${THIS_DIR}/diff-so-fancy-standalone"

${THIS_DIR}/third_party/build_fatpack/build.pl --output "${OUTPUT}"
