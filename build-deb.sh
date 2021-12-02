#!/bin/bash
if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	echo "Usage:"
	echo "	$0 <optional:version>"
	exit 0
elif [ "$1" = "" ]; then
	version=`git describe --tags --abbrev=0`
else
	version=$1
fi

buildName="screen-sbs_${version}_all"
mkdir -p build/$buildName/{usr/bin,DEBIAN}
cd build
cp ../screen.sh $buildName/usr/bin/screen

echo "Package: screen-sbs
Version: ${version}
Maintainer: mxve <hi@mxve.de>
Depends: scrot, xclip, curl
Architecture: all
Homepage: https://screen.sbs
Description: screen.sbs uploader" \
> $buildName/DEBIAN/control

dpkg --build $buildName
