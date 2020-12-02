#!/bin/bash
#
# UNTESTED!!!
#
#Invokes a web request for parameter --key and echoes the result.
#Usage:
#Output=$(source "Get-GCEInstanceMetadata.sh" "--Key" "KeyId")

Key=${Key:-""}

while [ $# -gt 0 ]; do
	if [[ $1 == *"--"* ]]; then
		param="${1/--/}"
		declare $param="$2"
		echo $1 $2
	fi
	shift
done

if [ -z $Key ]; then
	exit 1
fi

Content=$(curl -L -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/${Key}" | jq '.Content')

if [ -n "$Content" ]; then
	echo $Content
	exit 0
else
	echo "No content found!"
	exit 1
fi