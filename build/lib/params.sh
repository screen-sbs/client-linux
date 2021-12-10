if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	echo "Usage:"
	echo "	$0 <optional:version>"
	exit 0
elif [ "$1" = "" ]; then
	version=`git describe --tags --abbrev=0`
else
	version=$1
fi

IFS="-" read -a versArr <<< "$version"
version="${versArr[0]}"
revision="${versArr[1]}"