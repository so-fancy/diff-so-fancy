#!/bin/bash

clipboard() {
	local copy_cmd

	if [ -n "$PBCOPY_SERVER" ]; then
		local body="" # buffer
		body=$(cat)
		# while IFS= read -r buffer; do
		#   body="$body$buffer\n";
		# done
		curl "$PBCOPY_SERVER" --data-urlencode body="$body" >/dev/null 2>&1
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
	elif command -v pbcopy >/dev/null 2>&1; then
		copy_cmd="pbcopy"
	elif command -v xclip >/dev/null 2>&1; then
		# copy_cmd="xclip -i -selection clipboard"
		copy_cmd="xclip"
	elif command -v xsel >/dev/null 2>&1 ; then
		local copy_cmd="xsel -b"
	fi

	if [ -n "$copy_cmd" ] ;then
		eval "$copy_cmd"
	else
		echo "clipboard is unavailable" 1>&2
	fi
}

if [ $# -eq 0 ]; then
	echo "Usage: $0 'git diff HEAD..HEAD^'"
	exit 7
fi

file=${2:-dsf-bug-report.txt}

{
	echo "$1"
	eval "$1"
	echo ""
	echo ""
	echo ""

	echo "$1 --color"
	eval "$1 --color"

	echo "git config --list | grep pager"
	eval "git config --list | grep pager"
} | base64 > "$file"

echo "Wrote file: $file"
echo "Please open a new issue on Github and attach it"
