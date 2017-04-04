#!/bin/bash

if [ $# -lt 3 ]; then
	echo "error arguments should be localizabler \$input \$key \$localizableKey"
	exit
fi
echo "start search key $2 in $1..."

input=$1
output="$input.tmp"

key=$2 # "laO-HV-Dzx"
localizableKey=$3

if [ ! -e "$input" ]; then
	echo -e "\033[0;31mERROR: $input not found\033[0m"
	exit
fi

exist=$(xmlstarlet sel -t -c "count(//*[@id='$key'])" $input)
if [ $exist -eq 0 ]; then
	echo -e "\033[0;31mERROR: $key not found\033[0m"
	exit 1
fi

count=$(xmlstarlet sel -t -c "count(//*[@id='$key']/userDefinedRuntimeAttributes)" $input)
# echo -e "\033[0;31m$count\033[0m"
if [ $count -eq 0 ]; then #Create it
	echo "Create userDefinedRuntimeAttribute $key"
	xmlstarlet ed --subnode "//*[@id='$key']" --type elem -n userDefinedRuntimeAttributes -v "" --subnode "//*[@id='$key']/userDefinedRuntimeAttributes[last()]"  --type elem -n userDefinedRuntimeAttribute -v "" $input | xmlstarlet ed --insert "//*[@id='$key']/userDefinedRuntimeAttributes/userDefinedRuntimeAttribute" --type attr -n type -v string --insert "//*[@id='$key']/userDefinedRuntimeAttributes/userDefinedRuntimeAttribute" --type attr -n keyPath -v localizableString --insert "//*[@id='$key']/userDefinedRuntimeAttributes/userDefinedRuntimeAttribute" --type  attr -n value -v $localizableKey > $output && mv $output $input
else # update
	attributeCount=$(xmlstarlet sel -t -c "count(//*[@id='$key']/userDefinedRuntimeAttributes/userDefinedRuntimeAttribute[@keyPath='localizableString'])" $input)
	if [ $attributeCount -eq 0 ]; then #Create it
		echo "Update userDefinedRuntimeAttribute"
		xmlstarlet ed --subnode "//*[@id='$key']/userDefinedRuntimeAttributes[last()]" --type elem -n userDefinedRuntimeAttribute -v "" $input | xmlstarlet ed --insert "//*[@id='$key']/userDefinedRuntimeAttributes/userDefinedRuntimeAttribute[last()]" --type attr -n type -v string --insert "//*[@id='$key']/userDefinedRuntimeAttributes/userDefinedRuntimeAttribute[last()]" --type attr -n keyPath -v localizableString --insert "//*[@id='$key']/userDefinedRuntimeAttributes/userDefinedRuntimeAttribute[last()]" --type attr -n value -v $localizableKey > $output && mv $output $input
	fi
fi

echo -e "\033[0;32mDone with success <3\033[0m"

exit