#!/bin/bash

#setting default variable values;
FILE="$HOME""/allnotes.txt"
F_ADD=0
F_LIST=0

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

#If option list grep all lines begining form #
if [ $F_LIST -eq 1 ]; then
	grep  '^#' "$FILE" | tr ' ' '\n' | sort | uniq | more
	exit 0;
fi


#No tag specified
if [ ! $TAG ]; then
	echo 'You must to specify tag. Check -h.' >&2
	exit 1
fi


#Removine leading # form tag if there is one;
TAG=$(echo "$TAG" | sed 's/#\?\(.*\)/\1/g')

#If option add was used add tag to file and exit
if [ $F_ADD -eq 1 ]; then
	echo '#'$TAG >> "$FILE"
	echo $TEXT >> "$FILE"
	exit 1
fi

tmp_err(){
	echo "Failed to create temporary file.\nExiting" >&2
	exit 1;
}

#traping clean function to properly handle tmp files on exit or error
trap clean EXIT

temp_file_1=$(mktemp) || tmp_err
clean(){ rm -f ${temp_file_1};}

temp_file_2=$(mktemp) || tmp_err
clean(){ rm -f ${temp_file_1} ${temp_file_2}; }

DEDITOR='/usr/bin/editor' 

if [ ! -x $DEDITOR ]; then
	DEDITOR='vi'
fi

#escaping some awk special signs
E_TAG=$(echo "$TAG" | sed 's/\([+?^$|*(){}.]\)/\\\1/g')

if [ $? -ne 0 ]; then
	echo "SED error" >&2
	exit 1
fi

#Dividing note file into 2 files.
#1st containing notes starting with tag which we asked for,
#2nd containing the rest.
awk '/^#/{if(/(^|\s+)#'"$E_TAG"'(\s+|$)/){f=1}else{f=0} } {if(f){print >"'${temp_file_1}'"}else{ print >"'${temp_file_2}'"}}' "$FILE" 

if [ $? -ne 0 ]; then
	echo "AWK error. Exiting" >&2
	exit 1
fi

#storing last edit date
EDATE=$(stat -c %y $temp_file_1)


#If the selected tag does not exist, we ask if user want to create it.
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

#Selecting editor VISUAL > EDITOR > DEDITOR
M_EDITOR=${VISUAL:-${EDITOR:-${DEDITOR}}} 

$M_EDITOR "${temp_file_1}"

EDATE2=$(stat -c %y "$temp_file_1")

#check if last edition date has changed.
if [ "$EDATE" == "$EDATE2" ];then
	echo "No changes to apply."
	exit 0;
fi

#User edited file have to begin with # so if it's not,
#we ask him to edit it
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

#Commiting changes
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

