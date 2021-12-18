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
if [ "$saveLocally" = false ]; then
    savePath="/tmp/"
fi

# check wether notify-send is available
if ! [ -x "$(command -v notify-send)" ];then
	echo "notify-send not available, disabling all notifications.."
	disableNotifications=true
fi

# check wether ffmpeg is available
if ! [ -x "$(command -v ffmpeg)" ];then
	echo "ffmpeg not available, disabling video recording.."
	enableRecording=false
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
		serverUrl="https://screen.sbs/"
		token=""
		limitFullscreen=false
		fullscreenArea="0,0,1920,1080"
		enableRecording=true
		recordArea="0,0,1920,1080"
		recordDuration="10"
		recordCountdown=true
		disableNotifications=false

		mkdir -p $confPath
		touch $confPath$confFile
	fi

	# get settings from user, current variable value will be entered (-i)
	read -e -p "Save files locally? (true/false): " -i "$saveLocally" saveLocally
	read -e -p "Local save path: " -i $savePath savePath
	read -e -p "Open link after uploading? (true/false): " -i "$openLink" openLink
	read -e -p "Copy link after uploading? (true/false): " -i "$copyLink" copyLink
	read -e -p "Disable notifications? (true/false): " -i "$disableNotifications" disableNotifications
	read -e -p "Show link notification after uploading? (true/false): " -i "$linkNotification" linkNotification
	read -e -p "Server URL: " -i "$serverUrl" serverUrl
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
		echo "disableNotifications=${disableNotifications}"
		echo "linkNotification=${linkNotification}"
		echo "serverUrl=${serverUrl}"
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
	if [ "$disableNotifications" = false ]; then
		notify-send -i screen-sbs "screen-sbs" "$1"
	fi
}

# parameters:
# $1 - area: screenshot userselected area
# $1 - [any]: fullscreen
function screenshot {
	if [ "$1" = "area" ]; then
		# --line mode=edge fixes selection border showing up in screenshots
		scrot -s --line mode=edge "$filePath.png"
	else
		if [ "$limitFullscreen" = true ]; then
    		scrot -a $fullscreenArea -q 50 "$filePath.png"
		else
			scrot -q 50 "$filePath.png"
		fi
	fi

	filePath="${filePath}.png"
	upload
}

function text {
	touch "$filePath.txt"
	if [ -p /dev/stdin ]; then
		# get stdin (pipe)
		input=$(</dev/stdin)
		echo "$input" > "$filePath.txt"
    else
		# get clipboard text (ctrl+c clipboard)
		xclip -selection "clipboard" -o > "$filePath.txt"
    fi

	filePath="${filePath}.txt"
	upload
}

function video {
	# capture video using ffmpeg
	if [ "$enableRecording" = true ] ; then
		IFS="," read -ra recordArea <<< "$recordArea"

		# some notification services ignore the display time (-t)
		# so we allow the user to disable the countdown
		if [ "$recordCountdown" = true ] && [ "$disableNotifications" = false ]; then
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

		filePath="${filePath}.mp4"
		upload

		# manually remove the .avi recording as it tends to be quite big
		rm /tmp/screen-sbs-recording.avi
	else
		log "Recording is disabled, install ffmpeg or use '$0 config' to enable recording"
		exit 1
	fi
}

function upload {
	# get server configuration
	serverCfg=`curl -so - -w ";%{http_code}\n" "${serverUrl}/config"`
	# split status code from body
	IFS=";" read -ra serverCfg <<< "$serverCfg"
	# extract fileSizeLimit key
	fileSizeLimit=`echo ${serverCfg[0]} | jq .fileSizeLimit`
	# get size of file to upload
	fileSize=`du -m ${filePath} | cut -f1`

	if [[ "${serverCfg[1]}" -eq "000" ]]; then
		log "Error while getting server config, internet or server offline?"
		exit 1
	fi

	if [[ "$fileSize" -gt  "$fileSizeLimit" ]]; then
		log "File size exceeds server limit of ${fileSizeLimit}MB (${fileSize}MB)"
		exit 1
	fi

	# upload, get body & http status code
	response=`curl -so - -w ";%{http_code}\n" -F "file=@${filePath}" "${serverUrl}/upload/${token}"`

	# split status code from body
	IFS=";" read -ra response <<< "$response"
	body="${response[0]}"
	status="${response[1]}"

	# handle status codes
	# see https://github.com/screen-sbs/server/blob/master/README.md#status-codes
	# for all status codes
	# 000 = unreachable
	if [ "$status" = "000" ]; then
		log "Error while uploading, internet or server offline?"
		exit 1
	elif [ "$status" = "201" ]; then
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

# interactive menu
# uses dialog if installed, otherwise a simple native bash menu
function interactive {
	options=("Screenshot: fullscreen" "Screenshot: area" "Text from clipboard" "Video" "config" "quit")

	if [ -x "$(command -v dialog)" ]; then
		# build dialog menu from options
		cmd="dialog --menu --output-fd 1 \"screen.sbs\" 0 0 0"
		i=1
		for option in "${options[@]}"
		do
			cmd="${cmd} ${i} \"${option}\""
			((i=i+1))
		done

		# run dialog
		selection=`eval $cmd`
	else
		# fallback
		# build simple list menu from options
		i=1
		for option in "${options[@]}"
		do
			echo "${i}) ${option}"
			((i=i+1))
		done

		# get selection
		read -e -p "Selection: " selection
	fi

	# handle selection, same for dialog & fallback
	case $selection in
  		1)
    		screenshot "fullscreen"
    		;;
		2)
    		screenshot "area"
    		;;
		3)
    		text
    		;;
		4)
    		video
    		;;
		5)
    		config
    		;;
		6)
    		exit 0
    		;;
  		*)
		  	echo "Invalid selection"
    		interactive
    		;;
	esac
}

# build path
now=$(date +"%Y-%m-%d_%H-%M-%S-%3N")
# evaluate ~
dir="${savePath/#\~/$HOME}"
mkdir -p $dir
filePath="$dir/$now"

# handle script parameters
if [ "$1" = "" ]; then
	interactive
elif [ "$1" = "area" ]; then
	screenshot "area"
elif [ "$1" = "full" ] || [ "$1" = "fullscreen" ]; then
	screenshot "fullscreen"
elif [ "$1" = "text" ]; then
	text
elif [ "$1" = "video" ]; then
	# overrride recordDuration if $2 is set
	if [ -n "$2" ]; then
		recordDuration=$2
	fi
	video
elif [ "$1" = "file" ]; then
	if [ -z "$2" ]; then
		log "No file specified"
		exit 1
	fi
	if [[ $2 == *.png ]] || [[ $2 == *.txt ]] || [[ $2 == *.mp4 ]]; then
		filePath="$2"
		upload
	else
		log "Invalid file specified. Supported formats: png, mp4, txt"
		exit 1
	fi
elif [ "$1" = "version" ]; then
	echo $VERSION
elif [ "$1" = "config" ]; then
	config
else
	# couldn't match any parameter so we'll show the help menu
	echo "Usage:"
	echo "  ${0} <option>"
	echo "    Options:"
	echo "		[empty]"
	echo "			Interactive menu"
	echo "      full, fullscreen"
	echo "        Take fullscreen screenshot (across all screens)"
	echo "      area"
	echo "        Select an area to screenshot"
	echo "      text"
	echo "        Upload clipboard"
	echo "      video <optional:duration>"
	echo "        Record video (area defined in config)"
	echo "      file <filepath>"
	echo "        Upload file: .png, .txt, .mp4"
	echo "      config <optional:default>"
	echo "        Setup config file, use config default to start setup with default values"
	echo "      version"
	echo "        Get installed version"
fi
