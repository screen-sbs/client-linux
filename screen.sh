#!/bin/bash
VERSION="git_version"

confPath="~/.config/"
confFile="screen-sbs.conf"
confPath="${confPath/#\~/$HOME}"


function config() {
	if  test -f "$confPath$confFile" && [ "$1" = "" ]; then
		source $confPath$confFile
	else
		saveLocally=true
		openLink=true
		copyLink=true
		savePath="~/Documents/screen.sbs/"
		uploadUrl="https://screen.sbs/upload/"
		token=""

		mkdir -p $confPath
		touch $confPath$confFile
	fi

	read -e -p "Save files locally? (true/false): " -i "$saveLocally" saveLocally
	read -e -p "Local save path: " -i $savePath savePath
	read -e -p "Open link after uploading? (true/false): " -i "$openLink" openLink
	read -e -p "Copy link after uploading? (true/false): " -i "$copyLink" copyLink
	read -e -p "Upload URL: " -i "$uploadUrl" uploadUrl
	read -e -p "Upload token: " -i "$token" token

	{
		echo "saveLocally=${saveLocally}"
		echo "savePath=${savePath}"
		echo "openLink=${openLink}"
		echo "copyLink=${copyLink}"
		echo "uploadUrl=${uploadUrl}"
		echo "token=${token}"
	} > $confPath$confFile
}

if ! test -f "$confPath$confFile"; then
	echo "No config file found!"
	if [ "$1" != "config" ];  then
		config
	fi
else
	source $confPath$confFile
fi

if [ "$token" = "" ]; then
	echo "No token configured!"
	if [ "$1" != "config" ];  then
		config
	fi
fi

if [ "$saveLocally" = false ] ; then
    savePath="/tmp/"
fi


function area {
	scrot -s --line mode=edge "$filePath.png"
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
	response=`curl -sF "file=@${filePath}${1}" "$uploadUrl$token"`

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


now=$(date +"%Y-%m-%d_%H-%M-%S-%3N")
dir="${savePath/#\~/$HOME}"
mkdir -p $dir
filePath="$dir/$now"

if [ "$1" = "area" ]; then
	area
elif [ "$1" = "" ] || [ "$1" = "full" ] || [ "$1" = "fullscreen" ]; then
	fullscreen
elif [ "$1" = "text" ]; then
	text
elif [ "$1" = "version" ]; then
	echo $VERSION
elif [ "$1" = "config" ]; then
	config
else
	echo "Usage:"
	echo "  ${0} <option>"
	echo "    Options:"
	echo "      [empty], full, fullscreen"
	echo "        Take fullscreen screenshot (across all screens)"
	echo "      area"
	echo "        Select an area to screenshot"
	echo "      text"
	echo "        Upload clipboard"
	echo "      config <optional:default>"
	echo "        Setup config file, use config default to start setup with default values"
	echo "      version"
	echo "        Get installed version"
fi