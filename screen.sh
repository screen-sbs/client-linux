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
		limitFullscreen=false
		fullscreenArea="0,0,1920,1080"
		enableRecording=true
		recordArea="0,0,1920,1080"
		recordDuration="10"

		mkdir -p $confPath
		touch $confPath$confFile
	fi

	read -e -p "Save files locally? (true/false): " -i "$saveLocally" saveLocally
	read -e -p "Local save path: " -i $savePath savePath
	read -e -p "Open link after uploading? (true/false): " -i "$openLink" openLink
	read -e -p "Copy link after uploading? (true/false): " -i "$copyLink" copyLink
	read -e -p "Upload URL: " -i "$uploadUrl" uploadUrl
	read -e -p "Upload token: " -i "$token" token

	read -e -p "Limit fullscreen to specific area (screen)? (true/false): " -i "$limitFullscreen" limitFullscreen
	if [ "$limitFullscreen" = true ] ; then
    	read -e -p "Fullscreen area (x,y,w,h): " -i "$fullscreenArea" fullscreenArea
	fi

	read -e -p "Enable video recording? (true/false): " -i "$enableRecording" enableRecording
	if [ "$enableRecording" = true ] ; then
    	read -e -p "Video recording area (x,y,w,h): " -i "$recordArea" recordArea
		read -e -p "Recording duration (seconds): " -i "$recordDuration" recordDuration
	fi
	

	{
		echo "saveLocally=${saveLocally}"
		echo "savePath=${savePath}"
		echo "openLink=${openLink}"
		echo "copyLink=${copyLink}"
		echo "uploadUrl=${uploadUrl}"
		echo "token=${token}"
		echo "limitFullscreen=${limitFullscreen}"
		echo "fullscreenArea=${fullscreenArea}"
		echo "enableRecording=${enableRecording}"
		echo "recordArea=${recordArea}"
		echo "recordDuration=${recordDuration}"
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
	if [ "$saveLocally" = true ] ; then
    	scrot -a $fullscreenArea -q 50 "$filePath.png"
	else
		scrot -q 50 "$filePath.png"
	fi

	upload ".png"
}

function text {
	xclip -selection "clipboard" -o > "$filePath.txt"
	upload ".txt"
}

function video {
	if [ "$enableRecording" = true ] ; then
		IFS="," read -ra recordArea <<< "$recordArea"

		ffmpeg -loglevel quiet -f x11grab -y -t ${recordDuration} -r 25 \
			-s ${recordArea[2]}x${recordArea[3]} \
			-i :0.0+${recordArea[0]},${recordArea[1]} \
			-vcodec huffyuv /tmp/screen-sbs-recording.avi >/dev/null
		exitCode=$?

		if [ "$exitCode" != "0" ]; then
			echo "Error while recording using ffmpeg, exit code $exitCode"
			exit $exitCode
		fi

		ffmpeg -an -loglevel quiet -i /tmp/screen-sbs-recording.avi \
			-vcodec libx264 -pix_fmt yuv420p \
			-profile:v baseline ${filePath}.mp4 >/dev/null
		exitCode=$?

		if [ "$exitCode" != "0" ]; then
			echo "Error while encoding recording using ffmpeg, exit code $exitCode"
			exit $exitCode
		fi

		upload ".mp4"

		rm /tmp/screen-sbs-recording.avi
	else
		echo "Recording is disabled, use '$0 config' to enable recording"
		exit 1
	fi
}

# required parameters:
#   $1 file extension
#     .txt, .png, .mp4
function upload {
	response=`curl -o - -w ";%{http_code}\n" -sF "file=@${filePath}${1}" "$uploadUrl$token"`

	IFS=";" read -ra response <<< "$response"
	body="${response[0]}"
	status="${response[1]}"

	if [ "$status" = "201" ]; then
		echo $body
		if [ "$copyLink" = true ]; then
			echo $response | xclip -selection "clipboard"
		fi
		if [ "$openLink" = true ]; then
			xdg-open $response
		fi
	elif [ "$status" = "400" ]; then
		echo "Uploaded file was emtpy"
		echo "Check your paths and permissions"
		echo "$0 config"
	elif [ "$status" = "401" ]; then
		echo "Invalid upload token!"
		echo "Use $0 config to change your token"
	elif [ "$status" = "500" ]; then
		echo "Server error while handling upload"
	else
		echo $status
		echo "Error while uploading"
		echo "Check your upload url with $0 config"
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
elif [ "$1" = "video" ]; then
	video
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
	echo "      video"
	echo "        Record video (area defined in config)"
	echo "      config <optional:default>"
	echo "        Setup config file, use config default to start setup with default values"
	echo "      version"
	echo "        Get installed version"
fi