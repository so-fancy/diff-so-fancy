#!/bin/bash

DIFFHIGHLIGHT_RAW_URL_BASE="https://raw.githubusercontent.com/git/git/master/contrib/diff-highlight"
DIFFHIGHLIGHT_FILES=( "DiffHighlight.pm" "README" )

for file in "${DIFFHIGHLIGHT_FILES[@]}";
do
  url="$DIFFHIGHLIGHT_RAW_URL_BASE/$file"
  echo "$url"
  curl -#Lo "lib/$file" "$url"
done
