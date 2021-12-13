#!/bin/bash
VERSION="git_version"

confPath="~/.config/"
confFile="screen-sbs.conf"
confPath="${confPath/#\~/$HOME}"

# show config menu if file not found, otherwise load config
if ! test -f "$confPath$confFile"; then
	echo "No config file found!"
	if [ "$1" != "config" ];  then
		config
	fi
else
	source $confPath$confFile
fi

# check if token is set at all
if [ "$token" = "" ]; then
	echo "No token configured!"
	if [ "$1" != "config" ];  then
		config
	fi
fi

# if user doesn't want to save locally we'll put the files in /tmp/
if [ "$saveLocally" = false ] ; then
    savePath="/tmp/"
fi

# optional parameter
#	$1 <anything> -> use default settings
function config() {
	if  test -f "$confPath$confFile" && [ "$1" = "" ]; then
		# load current config file
		source $confPath$confFile
	else
		# use default settings
		saveLocally=true
		openLink=true
		copyLink=true
		linkNotification=true
		savePath="~/Documents/screen.sbs/"
		uploadUrl="https://screen.sbs/upload/"
		token=""
		limitFullscreen=false
		fullscreenArea="0,0,1920,1080"
		enableRecording=true
		recordArea="0,0,1920,1080"
		recordDuration="10"
		recordCountdown=true

		mkdir -p $confPath
		touch $confPath$confFile
	fi

	# get settings from user, current variable value will be entered (-i)
	read -e -p "Save files locally? (true/false): " -i "$saveLocally" saveLocally
	read -e -p "Local save path: " -i $savePath savePath
	read -e -p "Open link after uploading? (true/false): " -i "$openLink" openLink
	read -e -p "Copy link after uploading? (true/false): " -i "$copyLink" copyLink
	read -e -p "Show link notification after uploading? (true/false): " -i "$linkNotification" linkNotification
	read -e -p "Upload URL: " -i "$uploadUrl" uploadUrl
	read -e -p "Upload token: " -i "$token" token

	read -e -p "Limit fullscreen to specific area (screen)? (true/false): " -i "$limitFullscreen" limitFullscreen
	if [ "$limitFullscreen" = true ]; then
    	read -e -p "Fullscreen area (x,y,w,h): " -i "$fullscreenArea" fullscreenArea
	fi

	read -e -p "Enable video recording? (true/false): " -i "$enableRecording" enableRecording
	if [ "$enableRecording" = true ]; then
    	read -e -p "Video recording area (x,y,w,h): " -i "$recordArea" recordArea
		read -e -p "Recording duration (seconds): " -i "$recordDuration" recordDuration
		read -e -p "Enable notification countdown before recording (Don't use on gnome)? (true/false): " -i "$recordCountdown" recordCountdown
	fi
	

	# write settings to file, overwriting the existing config file
	{
		echo "saveLocally=${saveLocally}"
		echo "savePath=${savePath}"
		echo "openLink=${openLink}"
		echo "copyLink=${copyLink}"
		echo "linkNotification=${linkNotification}"
		echo "uploadUrl=${uploadUrl}"
		echo "token=${token}"
		echo "limitFullscreen=${limitFullscreen}"
		echo "fullscreenArea=${fullscreenArea}"
		echo "enableRecording=${enableRecording}"
		echo "recordArea=${recordArea}"
		echo "recordDuration=${recordDuration}"
		echo "recordCountdown=${recordCountdown}"
	} > $confPath$confFile
}

# required parameters:
#   $1 text
function log() {
	echo -e $1
	notify-send -i screen-sbs "screen-sbs" "$1"
}

function area {
	# get screenshot from user selected area
	# --line mode=edge fixes selection border showing up in screenshots
	scrot -s --line mode=edge "$filePath.png"
	upload ".png"
}

function fullscreen {
	# get fullscreen screenshot

	if [ "$limitFullscreen" = true ]; then
    	scrot -a $fullscreenArea -q 50 "$filePath.png"
	else
		scrot -q 50 "$filePath.png"
	fi

	upload ".png"
}

function text {
	# get clipboard text (ctrl+c clipboard)
	xclip -selection "clipboard" -o > "$filePath.txt"
	upload ".txt"
}

function video {
	# capture video using ffmpeg
	if [ "$enableRecording" = true ] ; then
		IFS="," read -ra recordArea <<< "$recordArea"

		# some notification services ignore the display time (-t)
		# so we allow the user to disable the countdown
		if [ "$recordCountdown" = true ] ; then
			for i in {3..1}
			do
				notify-send -i screen-sbs -t 1000 "screen-sbs" "Recording in ${i}"
				sleep 1
			done
		fi

		# record desktop in defined location and size
		ffmpeg -loglevel quiet -f x11grab -y -t ${recordDuration} -r 25 \
			-s ${recordArea[2]}x${recordArea[3]} \
			-i :0.0+${recordArea[0]},${recordArea[1]} \
			-vcodec huffyuv /tmp/screen-sbs-recording.avi >/dev/null
		exitCode=$?

		if [ "$exitCode" != "0" ]; then
			log "Error while recording using ffmpeg, exit code $exitCode"
			exit $exitCode
		fi

		log "Recording finished.\nProcessing.."

		# encode x264 mp4 for upload
		ffmpeg -an -loglevel quiet -i /tmp/screen-sbs-recording.avi \
			-vcodec libx264 -pix_fmt yuv420p \
			-profile:v baseline ${filePath}.mp4 >/dev/null
		exitCode=$?

		if [ "$exitCode" != "0" ]; then
			log "Error while encoding recording using ffmpeg, exit code $exitCode"
			exit $exitCode
		fi

		upload ".mp4"

		# manually remove the .avi recording as it tends to be quite big
		rm /tmp/screen-sbs-recording.avi
	else
		log "Recording is disabled, use '$0 config' to enable recording"
		exit 1
	fi
}

# required parameters:
#   $1 file extension
#     .txt, .png, .mp4
function upload {
	# upload, get body & http status code
	response=`curl -o - -w ";%{http_code}\n" -sF "file=@${filePath}${1}" "$uploadUrl$token"`

	# split status code from body
	IFS=";" read -ra response <<< "$response"
	body="${response[0]}"
	status="${response[1]}"

	# handle status codes
	# see https://github.com/screen-sbs/server/blob/master/README.md#status-codes
	# for all status codes
	if [ "$status" = "201" ]; then
		if [ "$copyLink" = true ]; then
			echo $body | xclip -selection "clipboard"
			if [ "$linkNotification" = false ]; then
				log "Link copied to clipboard"
			fi
		fi
		if [ "$linkNotification" = true ]; then
			log $body
		else
			echo $body
		fi
		if [ "$openLink" = true ]; then
			xdg-open $body
		fi
		exit 0
	elif [ "$status" = "400" ]; then
		log "Uploaded file was empty\nCheck your paths and permissions\n$0 config"
		exit 1
	elif [ "$status" = "401" ]; then
		log "Invalid upload token!\nUse $0 config to change your token"
		exit 1
	elif [ "$status" = "413" ]; then
		log "File size limit exceeded!\nIf this was a video, lower the max duration\n$0 config"
		exit 1
	elif [ "$status" = "500" ]; then
		log "Server error while handling upload"
		exit 1
	else
		echo $status
		log "Error while uploading\nCheck your upload url with $0 config"
		exit 1
	fi
}


now=$(date +"%Y-%m-%d_%H-%M-%S-%3N")
dir="${savePath/#\~/$HOME}"
mkdir -p $dir
filePath="$dir/$now"

if [ "$1" = "" ]; then
	echo "interactive menu not implemented, yet"
elif [ "$1" = "area" ]; then
	area
elif [ "$1" = "full" ] || [ "$1" = "fullscreen" ]; then
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
	# couldn't match any parameter so we'll show the help menu
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