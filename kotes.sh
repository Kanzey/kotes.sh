#!/bin/bash

FILE="$HOME""/allnotes.txt"

while getopts ':t:lf:h:a:' opt; do
	case $opt in
		h)
			echo "Options:"
			echo "	-l				List #tags"
			echo "	-t	<tagname>	Select tag to edit"
			echo "	-f	<filename>	Select file to edit"
			echo "	-a	<text>		Add text with tag without opening editor"
			exit 0	
			;;
		a)
			F_ADD=1
			TEXT=$OPTARG
			;;
		l) 
			F_LIST=1
			;;
		t)
			TAG=$OPTARG
			;;
		f)
			FILE=$OPTARG
			if [ ! -f "$FILE" ]; then
				echo "Unable to open file $FILE." >&2
				exit 1
			fi
			;;
		\?)
			echo "Invaild option -$OPTARG. Use option -h for help." >&2
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
			;;
	esac
done

if [ $F_LIST ]; then
	grep  '^#' "$FILE" | tr ' ' '\n' | sort | uniq | more
	exit 0;
fi

if [ ! $TAG ]; then
	echo 'You must to specify tag. Check -h.' >&2
	exit 1
fi

if [ $F_ADD ]; then
	echo '#'$TAG >> "$FILE"
	echo $TEXT >> "$FILE"
	exit 1
fi

temp_file_1=$(mktemp)
if [ ! -f "$temp_file_1" ]; then
	echo "Unable to create tmp file." >&2
	exit 1
fi

temp_file_2=$(mktemp)
if [ ! -f "$temp_file_2" ]; then
	echo "Unable to create tmp file." >&2
	rm -f "${temp_file_1}"
	exit 1
fi

DEDITOR='/usr/bin/editor' 

if [ ! -x $DEDITOR ]; then
	DEDITOR='vi'
fi

awk '/^#/{if(/(^|\s+)#'$TAG'(\s+|$)/){f=1}else{f=0} } {if(f){print >"'${temp_file_1}'"}else{ print >"'${temp_file_2}'"}}' "$FILE" 

EDATE=$(stat -c %y $temp_file_1)

if [ ! -s "${temp_file_1}" ];then
	read -p "Tag does not exist. Do you want it to be created? [Y/n]" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]];then
		echo '#'$TAG > "${temp_file_1}"
	else
		rm -r "${temp_file_1}" "${temp_file_2}"
		exit 0
	fi
fi

${VISUAL:-${EDITOR:-${DEDITOR}}} "${temp_file_1}"

EDATE2=$(stat -c %y "$temp_file_1")

if [ "$EDATE" == "$EDATE2" ];then
	echo "No changes to apply."
else
	read -p "Do you want to commit changes? [Y/n]" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		cat "${temp_file_1}" "${temp_file_2}" > "$FILE"
	fi
fi
rm -f "${temp_file_1}" "${temp_file_2}"
