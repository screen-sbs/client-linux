#!/bin/bash
source lib/params.sh

mkdir -p build/bash
cp ../screen.sh build/bash/screen-sbs_${version}-${revision}.sh
sed -i "s/git_version/${version}-${revision}/g" build/bash/screen-sbs_${version}-${revision}.sh
