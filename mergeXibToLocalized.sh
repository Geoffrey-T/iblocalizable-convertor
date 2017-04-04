#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m'

numberOfDeprecatedTranslation=0
numberOfNewFileMerged=0

AppendFileIntoFile () {
	if [ ! -d $tradDir ]; then
		mkdir $tradDir
	fi

	echo -e "grep -q \"$file\" \"$tradFile\""
	if grep -q "$file" "$tradFile"; then
		echo -e "${ORANGE}[WARNING]${NC}    $file ${RED}is already in${NC} $tradFile"	
		return 1
	fi

	numberOfNewFileMerged=$((numberOfNewFileMerged+1))

	echo -e "\n\n\n\n\n" >> $tradFile
	echo -e "/* ################################################################################" >> $tradFile
	echo -e "##########   $file" >> $tradFile
	echo -e "################################################################################ */\n\n" >> $tradFile
	cat $file >> $tradFile

	echo -e "${GREEN}[OK]${NC}    $file ${ORANGE}copied to${NC} $tradFile\n\n\n"	
}

AddKeyToXIB () {
	localizedKeysWithAttribute=($(grep -Eo --binary-files=text "\"\w{3}-\w{2}-\w{3}\..+?\"" $file | sed 's/\"//g'))

	IFS=$'\n'
	localizedKeys=($(grep -Eo --binary-files=text "\"\w{3}-\w{2}-\w{3}\." $file | sed 's/[\.\"]//g'))
	unset IFS

	# Check if both array has same amount of elements
	# if [ ! ${#localizedKeysWithAttribute[@]}  -eq ${#localizedKeys[@]} ]; then
	# 	echo -e "${RED}${file}${NC}"		
	# fi

	fileBasename="$(basename $file)"
	fileBasenameNaked="${fileBasename%.*}"

	ViewFile=$(find $location -name $fileBasenameNaked.xib | head -n 1)

	if [ ! -e "$ViewFile" ]; then
		echo -e "${ORANGE}WARNING: $ViewFile not found, maybe it's a storyboard${NC}"
		ViewFile=$(find $location -name $fileBasenameNaked.storyboard | head -n 1)

		if [ ! -e "$ViewFile" ]; then
			echo -e "${RED}ERROR: $ViewFile not found, there is no view linked to this translation file (.strings): $file${NC}"
			return 1
		fi
	fi

	for index in "${!localizedKeys[@]}"; do
		echo -e "$ViewFile ${localizedKeys[index]} ${localizedKeysWithAttribute[index]}"
		./localizabler.sh $ViewFile ${localizedKeys[index]} ${localizedKeysWithAttribute[index]}

		if [ $? -eq 1 ]; then
			echo -e "${RED}${localizedKeys[index]} doesn't exist in xib/storyboard file${NC}"
			numberOfDeprecatedTranslation=$((numberOfDeprecatedTranslation+1))
			sed -i "" "/${localizedKeys[index]}/d" $file
		fi
	done

	return 0
}

if [ -z "$1" ]; then
	echo -e "${RED}Infos:${NC}"
	echo -e "It merges all the translation files (*.lproj) in the desire location into a single one per language\n"
	echo -e "${RED}Usage:${NC}"
	echo -e "$0 [location]"
	exit
else
	location=$1
fi

count=$(ls -1 $location/AppDelegate.* 2>/dev/null | wc -l)
if [ $count == 0 ]; then
	echo -e "${RED}ERROR: the following location is not a valid iOS project directory: ${ORANGE}$location${NC}"
	exit
fi

languagesArray=("Base" "en" "es" "fr" "it" "lo-LA" "pt-PT" "th")

for each in ${languagesArray[@]}; do
	tradDir="$location/$each.lproj"
	tradFile="$tradDir/Localizable.strings"

	for file in $(find ${location} -name *.strings); do

		if [[ $file == *"$each.lproj"* ]]; then

			if AddKeyToXIB; then
				AppendFileIntoFile
			fi
		fi
	done
done

echo -e "\n\nThere was ${RED}$numberOfDeprecatedTranslation${NC} deprecated translations !!!"
echo -e "And ${RED}$numberOfNewFileMerged${NC} new file merged !!!"

exit

#${@:$n:1} -> in all arguments, nth argument, until 1 more1
