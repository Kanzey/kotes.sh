#!/bin/bash

FILE="$HOME""/allnotes.txt"
F_ADD=0
F_LIST=0
F_VERB=0
while getopts ':t:lf:h:a:v' opt; do
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
		v)
			F_VERB=1
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

if [ $F_LIST -eq 1 ]; then
	grep  '^#' "$FILE" | tr ' ' '\n' | sort | uniq | more
	exit 0;
fi

if [ ! $TAG ]; then
	echo 'You must to specify tag. Check -h.' >&2
	exit 1
fi

TAG=$(echo "$TAG" | sed 's/#\?\(.*\)/\1/g')

if [ $F_ADD -eq 1 ]; then
	echo '#'$TAG >> "$FILE"
	echo $TEXT >> "$FILE"
	exit 1
fi

tmp_err(){
	echo "Failed to create temporary file.\nExiting" >&2
	exit 1;
}

trap clean EXIT
temp_file_1=$(mktemp) || tmp_err
clean(){ rm -f ${temp_file_1};}
temp_file_2=$(mktemp) || tmp_err
clean(){ rm -f ${temp_file_1} ${temp_file_2}; }

DEDITOR='/usr/bin/editor' 

if [ ! -x $DEDITOR ]; then
	DEDITOR='vi'
fi

E_TAG=$(echo "$TAG" | sed 's/\([+?^$|*(){}.]\)/\\\1/g')

if [ ! $? -eq 0 ]; then
	echo "SED error" >&2
	exit 1
fi

awk '/^#/{if(/(^|\s+)#'"$E_TAG"'(\s+|$)/){f=1}else{f=0} } {if(f){print >"'${temp_file_1}'"}else{ print >"'${temp_file_2}'"}}' "$FILE" 

if [ ! $? -eq 0 ]; then
	echo "AWK error. Exiting" >&2
	exit 1
fi

EDATE=$(stat -c %y $temp_file_1)

if [ ! -s "${temp_file_1}" ];then
	while true; do
		read -p "Tag does not exist. Do you want it to be created? [Y/n]" -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]];then
			echo '#'$TAG > "${temp_file_1}"
			break
		elif [[ $REPLY =~ ^[Nn]$ ]];then	
			exit 0
		fi
	done
fi

M_EDITOR=${VISUAL:-${EDITOR:-${DEDITOR}}} 

$M_EDITOR "${temp_file_1}"
EDATE2=$(stat -c %y "$temp_file_1")

if [ "$EDATE" == "$EDATE2" ];then
	echo "No changes to apply."
	exit 0;
fi

while true; do
	if [ "$(sed -n '1s/^#.*/0/p' ${temp_file_1})" != "0" ]; then
		read -p "Lack of leading # [E]dit or [D]iscard?" -n 1 -r
		echo
		if [[ $REPLY =~ ^[Ee]$ ]];then
			$M_EDITOR "${temp_file_1}"
		elif [[ $REPLY =~ ^[Dd]$ ]];then
			exit 0;
		fi
	else
		break;
	fi
done

while true;do
	read -p "Do you want to commit changes? [Y/n]" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]];then
		cat "${temp_file_1}" "${temp_file_2}" > "$FILE"
		exit 0
	elif [[ $REPLY =~ ^[Nn]$ ]];then
		exit 0
	fi
done

