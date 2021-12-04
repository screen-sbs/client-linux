#!/bin/bash
source lib/params.sh

buildName="screen-sbs_${version}-${revision}_all"
mkdir -p build/deb/$buildName/{usr/bin,DEBIAN}
cd build/deb
cp ../../../screen.sh $buildName/usr/bin/screen-sbs

sed -i "s/git_version/${version}-${revision}/g" $buildName/usr/bin/screen-sbs

echo "Package: screen-sbs
Version: ${version}-${revision}
Maintainer: mxve <hi@mxve.de>
Depends: scrot, xclip, curl
Architecture: all
Homepage: https://screen.sbs
Description: screen.sbs uploader" \
> $buildName/DEBIAN/control

dpkg --build $buildName
