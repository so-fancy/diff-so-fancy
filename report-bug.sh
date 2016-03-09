#!/bin/bash

clipboard() {
  local copy_cmd
  if [ -n "$PBCOPY_SERVER" ]; then
    local body="" buffer
    body=$(cat)
    # while IFS= read -r buffer; do
    #   body="$body$buffer\n";
    # done
    curl $PBCOPY_SERVER --data-urlencode body="$body" >/dev/null 2>&1
    return $?
  fi
  if type putclip >/dev/null 2>&1; then
    copy_cmd="putclip"
  elif [ -e /dev/clipboard ];then
    cat > /dev/clipboard
    return 0
  elif type clip >/dev/null 2>&1; then
    if [[ $LANG = UTF-8 ]]; then
      copy_cmd="iconv -f utf-8 -t shift_jis | clip"
    else
      copy_cmd=clip
    fi
    # copy_cmd=clip
  elif which pbcopy >/dev/null 2>&1; then
    copy_cmd="pbcopy"
  elif which xclip >/dev/null 2>&1; then
    # copy_cmd="xclip -i -selection clipboard"
    copy_cmd="xclip"
  elif which xsel  >/dev/null 2>&1 ; then
    local copy_cmd="xsel -b"
  fi
  if [ -n "$copy_cmd" ] ;then
    eval $copy_cmd
  else
    echo "clipboard is unavailable" 1>&2
  fi
}

file=${2:-diff.txt}

echo $1 > $file
eval $1 >> $file

echo "

" >> $file

echo "$1 --color" >> $file
eval "$1 --color" >> $file

echo "git config pager.diff" >> $file
eval "git config pager.diff" >> $file

echo "git config pager.show" >> $file
eval "git config pager.show" >> $file

cat $file | base64 | clipboard
