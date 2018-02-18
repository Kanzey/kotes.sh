#!/bin/bash

FILE='allnotes.txt';

while getopts ':t:lf:h' opt; do
	case $opt in
		h)
			echo "Options:"
			echo "	-l				List #tags"
			echo "	-t	<tagname>	Select tag to edit"
			echo "	-f	<filename>	Select file to edit"
			exit 0	
			;;
		l) 
			F_LIST=1;
			;;
		t)
			TAG=$OPTARG;
			;;
		f)
			FILE=$OPTARG
			if [ ! -f $FILE ]; then
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
	grep -i '^#' $FILE | tr ' ' '\n' | sort | uniq | more
	exit 0;
fi

if [ ! $TAG ]; then
	echo 'You must to specify tag. Check -h.';
	exit 1
fi

temp_file_1=$(mktemp)
if [ ! -f $temp_file_1 ]; then
	echo "Unable to create tmp file."
	exit 1
fi

temp_file_2=$(mktemp)
if [ ! -f $temp_file_2 ]; then
	echo "Unable to create tmp file."
	rm -rf ${temp_file_1}
	exit 1
fi

if [ -x /usr/bin/editor ]; then
	default_editor=/usr/bin/editor;
else
	default_editor=vi;
fi

awk '/^#/{if(/(^|\s+)#'$TAG'(\s+|$)/){f=1}else{f=0} } {if(f){print >"'${temp_file_1}'"}else{ print >"'${temp_file_2}'"}}' $FILE 

if [ ! -s ${temp_file_1} ];then
	read -p "Tag does not exist. Do you want to it to be created? " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]];then
		echo '#'$TAG > ${temp_file_1}
	else
		rm -rf ${temp_file_1} ${temp_file_2}
		exit 0
	fi
fi

${VISUAL:-${EDITOR:-${default_editor}}} ${temp_file_1}

read -p "Do you want to commit changes? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	cat ${temp_file_1} ${temp_file_2} > $FILE
fi

rm -rf ${temp_file_1} ${temp_file_2}
