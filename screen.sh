#!/bin/bash

confPath="~/.config/"
confFile="screen-sbs.conf"
confPath="${confPath/#\~/$HOME}"

if ! test -f "$confPath$confFile"; then
	mkdir -p $confPath
	touch $confPath$confFile
	echo 'saveLocally=true' > $confPath$confFile
	echo 'openLink=true' >> $confPath$confFile
	echo 'copyLink=true' >> $confPath$confFile
	echo 'savePath="~/Documents/screen.sbs/"' >> $confPath$confFile
	echo 'uploadUrl="https://upload.screen.sbs/"' >> $confPath$confFile
	echo 'token=""' >> $confPath$confFile
fi
source $confPath$confFile

mkdir -p $confPath

if [ "$token" = "" ] ; then
    echo "Configure your upload token in $confPath$confFile"
	exit 1
fi

if [ "$saveLocally" = false ] ; then
    savePath="/tmp/"
fi

now=$(date +"%Y-%m-%d_%H-%M-%S-%3N")
dir="${savePath/#\~/$HOME}"
mkdir -p $dir
filePath="$dir/$now"

function area {
	scrot -s "$filePath.png"
	upload ".png"
}

function fullscreen {
	scrot -q 50 "$filePath.png"
	upload ".png"
}

function text {
	xclip -selection "clipboard" -o > "$filePath.txt"
	upload ".txt"
}

# required parameters:
#   $1 file extension
#     .txt, .png, (.mp4)
function upload {
	response=`curl -sF "file=@${filePath}${1}" "$uploadUrl?token=$token"`

	# assume upload was successful if response body starts with http
	if [[ $response == http* ]]; then
		echo $response
		if [ "$copyLink" = true ]; then
			echo $response | xclip -selection "clipboard"
		fi
		if [ "$openLink" = true ]; then
			xdg-open $response
		fi
	else
		echo "error while uploading"
	fi
}

if [ "$1" = "area" ]; then
	area
elif [ "$1" = "" ] || [ "$1" = "full" ] || [ "$1" = "fullscreen" ]; then
	fullscreen
elif [ "$1" = "text" ]; then
	text
fi